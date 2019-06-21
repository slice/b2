struct TagNamespace {
    let id: Int
    let namespace: String
}

extension TagNamespace: CustomStringConvertible {
    var description: String {
        return self.namespace
    }
}
