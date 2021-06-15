import Foundation

struct OuroborosTag: BooruTag {
    init(text: String) {
        self.namespace = nil
        self.subtag = text
    }

    init(namespace: String?, subtag: String) {
        self.namespace = namespace
        self.subtag = subtag
    }

    var namespace: String?
    var subtag: String
}
