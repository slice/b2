struct Tag {
    let tag: String
    let namespace: TagNamespace?

    init(_ tag: String, namespace: TagNamespace? = nil) {
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
