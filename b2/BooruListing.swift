//
//  BooruListing.swift
//  b2
//
//  Created by slice on 6/21/21.
//  Copyright © 2021 slice. All rights reserved.
//

import os.log

/// An ordered collection of posts from a booru. The posts are separated into
/// logical chunks, which may be derived from pages of posts fetched from a
/// booru. Facilities are provided for loading additional chunks from paginated
/// responses or relative to other chunks, and for tracking this state between
/// fetches.
///
/// Chunk arrays should never be empty.
public class BooruListing {
    /// The chunks of posts in this listing.
    var chunks: [[BooruFile]]

    /// All posts in this listing.
    var posts: [BooruFile] {
        Array(self.chunks.joined())
    }

    /// The count of all posts within this listing.
    var count: Int {
        self.chunks.map(\.count).reduce(0, +)
    }

    /// The booru the files are associated with.
    unowned var booru: Booru

    private var nextQuery: BooruQueryOffset = .none

    private let log = Logger(subsystem: loggingSubsystem, category: "listing")

    /// Creates a listing from an array of chunks and the booru the posts
    /// came from. Any chunk arrays and the array of chunks itself may not be
    /// empty.
    init(chunks: [[BooruFile]], fromBooru originatingBooru: Booru) {
        guard !chunks.isEmpty else {
            fatalError("no chunks were given")
        }

        guard !chunks.contains(where: \.isEmpty) else {
            fatalError("a chunk was empty")
        }

        self.chunks = chunks
        self.booru = originatingBooru

        let preferredPaginationType = self.preferredPaginationType()
        switch preferredPaginationType {
        case .pages:
            self.nextQuery = .pageNumber(1)
        case .relativeToLowestPreviousID:
            self.nextQuery = .previousChunk(chunks[0])
        case .none:
            self.nextQuery = .none
        }
    }

    /// Creates a listing from a single chunk of posts and the booru the posts
    /// came from. The chunk must not be empty.
    convenience init(files firstChunk: [BooruFile], fromBooru originatingBooru: Booru) {
        guard !firstChunk.isEmpty else {
            fatalError("firstChunk is empty")
        }

        self.init(chunks: [firstChunk], fromBooru: originatingBooru)
    }

    func loadMorePosts(withTags tags: [String], completionHandler: @escaping (Result<[BooruFile], Error>) -> Void) {
        self.nextQuery = self.computeNewNextQuery()
        self.booru.search(forTags: tags, offsetBy: self.nextQuery) { result in
            if case .success(let posts) = result {
                self.log.info("new chunk has \(posts.count) post(s)")
                self.chunks.append(posts)
            }

            completionHandler(result)
        }
    }

    private func preferredPaginationType() -> BooruPaginationType {
        guard let preferredPaginationType = self.booru.supportedPaginationTypes.max() else {
            fatalError("found no supported pagination types when attempting to determine preferred pagination type")
        }

        return preferredPaginationType
    }

    private func computeNewNextQuery() -> BooruQueryOffset {
        if case .pageNumber(let pageNumber) = self.nextQuery {
            return .pageNumber(pageNumber + 1)
        } else if case .previousChunk(_) = self.nextQuery, let lastChunk = self.chunks.last {
            return .previousChunk(lastChunk)
        } else {
            self.log.info("new next query is none")
            return .none
        }
    }
}
