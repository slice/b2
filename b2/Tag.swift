struct Tag {
    let id: Int
    let tag: String
    let namespace: TagNamespace?

    init(id: Int, tag: String, namespace: TagNamespace? = nil) {
        self.id = id
        self.tag = tag
        self.namespace = namespace
    }
}

extension Tag: CustomStringConvertible {
    var description: String {
        let namespacePrefix = self.namespace != nil ? "\(self.namespace!):" : ""
        return "\(namespacePrefix)\(self.tag)"
    }
}
