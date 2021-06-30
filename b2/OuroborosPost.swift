//
//  OuroborosPost.swift
//  b2
//
//  Created by slice on 6/29/21.
//  Copyright © 2021 slice. All rights reserved.
//

import Cocoa

private func extractHashChunks(_ hash: String) -> (Substring, Substring) {
  let chunk1 = hash[hash.startIndex..<hash.index(hash.startIndex, offsetBy: 2)]
  let chunk2 = hash[
    hash.index(hash.startIndex, offsetBy: 2)..<hash.index(hash.startIndex, offsetBy: 4)]
  return (chunk1, chunk2)
}

private func synthesizeImageURL(response: OuroborosPostResponse, isPreview: Bool, host: String)
  -> URL
{
  let (chunk1, chunk2) = extractHashChunks(response.md5)
  let previewComponent = isPreview ? "preview/" : ""
  let ext = isPreview ? "jpg" : response.ext
  let url =
    "https://static1.\(host)/data/\(previewComponent)\(chunk1)/\(chunk2)/\(response.md5).\(ext)"
  guard let url = URL(string: url) else {
    fatalError("failed to synthesize a valid image url")
  }
  return url
}

class OuroborosPost {
  private var response: OuroborosPostResponse
  weak var originatingBooru: OuroborosBooru?

  public var globalID: String
  public var imageURL: URL
  public var thumbnailImageURL: URL

  init(response: OuroborosPostResponse, originatingBooru booru: OuroborosBooru) {
    self.response = response
    self.globalID = booru.formGlobalID(withBooruID: self.response.id)

    guard let host = booru.baseUrl.host else {
      fatalError("originatingBooru's baseUrl has no host")
    }
    self.imageURL =
      response.imageURL ?? synthesizeImageURL(response: response, isPreview: false, host: host)
    self.thumbnailImageURL =
      response.thumbnailImageURL
      ?? synthesizeImageURL(response: response, isPreview: true, host: host)
  }
}

extension OuroborosPost: BooruPost {
  var id: Int {
    self.response.id
  }

  var createdAt: Date {
    self.response.createdAt
  }

  var size: Int {
    self.response.size
  }

  var mime: BooruMime {
    guard let mime = BooruMime(extension: self.response.ext) else {
      fatalError("failed to glean BooruMime from OuroborosPostResponse")
    }
    return mime
  }

  var tags: [BooruTag] {
    self.response.tags.flatMap { namespace, tags -> [OuroborosTag] in
      let normalizedNamespace: String? = namespace == "general" ? nil : namespace
      return tags.map { OuroborosTag(namespace: normalizedNamespace, subtag: $0) }
    }
  }
}
