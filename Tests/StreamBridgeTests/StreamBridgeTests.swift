import Foundation
import Testing

@testable import StreamBridge

struct Metadata {
    var user: String
    var hotWords: [String]
}

struct TranscriptionSegment {
    var id: UInt16
    var time: UInt16
    var text: String
}

struct ActorState {
    var id: Int
    var time: Int
    var metadata: Metadata
    var confirmed: [TranscriptionSegment]
    var unconfirmed: [TranscriptionSegment]
    var current: String
}

@Test func testObjectBoxTypeMapping() {
    assert(toOboxType(String.self) == .string)
    assert(toOboxType(Int.self) == .long)
    assert(toOboxType(Bool.self) == .bool)
    assert(toOboxType(Data.self) == .byteVector)
}

@Test func testTypeRegistryBuilder() async throws {
    let fixtures = Fixtures()
    let structSig: ObjectAnnotation = ObjectAnnotation.build(ActorState.self)
    assert(structSig.name == fixtures.expectedAnnotation.name)
    for field in fixtures.expectedAnnotation.fields {
        let generatedAnn = unWrapAnn(structSig.fields[field.key]!)
        let fixtureAnn = unWrapAnn(field.value)
        switch field.value {
        case .simpleAtt:
            let gsa = generatedAnn as! SimpleAnnotation
            let fsa = fixtureAnn as! SimpleAnnotation
            assert(gsa.type == fsa.type)
        case .simpleArrayAtt:
            let gsa = generatedAnn as! SimpleArrayAnnotation
            let fsa = fixtureAnn as! SimpleArrayAnnotation
            assert(gsa.type == fsa.type)
        case .objectAtt:
            let gsa = generatedAnn as! ObjectAnnotation
            let fsa = fixtureAnn as! ObjectAnnotation
            for neededKey in fsa.fields.keys {
                assert(gsa.fields.keys.contains(neededKey), "\(neededKey) missing")
            }
        case .recordArrayAtt:
            let gsa = generatedAnn as! RecordArrayAnnotation
            let fsa = fixtureAnn as! RecordArrayAnnotation
            for neededKey in fsa.object.fields.keys {
                assert(gsa.object.fields.keys.contains(neededKey), "\(neededKey) missing")
            }

        }
    }

}

struct Fixtures {
    let expectedAnnotation: ObjectAnnotation = ObjectAnnotation(
        name: "ActorState",
        fields: [
            "id": AttributeType.simpleAtt(
                SimpleAnnotation(type: Int.self)),
            "time": AttributeType.simpleAtt(
                SimpleAnnotation(type: Int.self)),
            "unconfirmed": AttributeType.recordArrayAtt(
                RecordArrayAnnotation(
                    object: ObjectAnnotation(
                        name: "TranscriptionSegment",
                        fields: [
                            "id": AttributeType.simpleAtt(
                                SimpleAnnotation(type: UInt16.self)),
                            "time": AttributeType.simpleAtt(
                                SimpleAnnotation(type: UInt16.self)),
                            "text": AttributeType.simpleAtt(
                                SimpleAnnotation(type: String.self)),
                        ]))),
            "confirmed": AttributeType.recordArrayAtt(
                RecordArrayAnnotation(
                    object: ObjectAnnotation(
                        name: "TranscriptionSegment",
                        fields: [
                            "time": AttributeType.simpleAtt(
                                SimpleAnnotation(type: UInt16.self)),
                            "text": AttributeType.simpleAtt(
                                SimpleAnnotation(type: String.self)),
                            "id": AttributeType.simpleAtt(
                                SimpleAnnotation(type: UInt16.self)),
                        ]))),
            "current": AttributeType.simpleAtt(
                SimpleAnnotation(type: String.self)),
            "metadata": AttributeType.objectAtt(
                ObjectAnnotation(
                    name: "Metadata",
                    fields: [
                        "user": AttributeType.simpleAtt(
                            SimpleAnnotation(type: String.self)),
                        "hotWords": AttributeType.simpleArrayAtt(
                            SimpleArrayAnnotation(type: String.self)),
                    ])),
        ])
}
