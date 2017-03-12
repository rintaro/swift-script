import Runes
import TryParsec

fileprivate func asType(ty: Type_) -> Type_ {
    return ty
}

let type = _type()
func _type() -> SwiftParser<Type_> {
    return (typeIdent <&> asType)
        <|> (typeArray <&> asType)
        <|> (typeDictionary <&> asType)
}

let typeIdent = _typeIdent()
func _typeIdent() -> SwiftParser<TypeIdentifier­> {
    return { name in
        TypeIdentifier­(names: [name]) }
        <^> identifier
}

let typeArray = _typeArray()
func _typeArray() -> SwiftParser<ArrayType> {
    return { ty in
        ArrayType(type: ty) }
        <^> l_square *> type <* r_square
}


let typeDictionary = _typeDictionary()
func _typeDictionary() -> SwiftParser<DictionaryType> {
    return { key in { value in
        DictionaryType(keyType: key, valueType: value) }}
        <^> l_square
        *> type
        <*> colon *> type
        <* r_square
}
