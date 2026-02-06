import Foundation
import Testing
@testable import Aria2Kit

@Suite("Aria2Kit Tests")
struct Aria2KitTests {
    @Test("RPC request encodes with token")
    func rpcRequestEncoding() throws {
        let request = RPCRequest(
            method: .addUri,
            params: [.array([.string("https://example.com/file.zip")])],
            token: "peeri"
        )

        let data = try JSONEncoder().encode(request)
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]

        #expect(json?["jsonrpc"] as? String == "2.0")
        #expect(json?["method"] as? String == "aria2.addUri")

        let params = json?["params"] as? [Any]
        #expect(params?.count == 2)
        #expect(params?.first as? String == "token:peeri")
    }

    @Test("RPC request encodes without token")
    func rpcRequestNoToken() throws {
        let request = RPCRequest(
            method: .getVersion,
            params: [],
            token: nil
        )

        let data = try JSONEncoder().encode(request)
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]

        let params = json?["params"] as? [Any]
        #expect(params?.isEmpty == true)
    }

    @Test("Version response decodes")
    func versionResponseDecoding() throws {
        let json = """
        {"id":"1","jsonrpc":"2.0","result":{"version":"1.37.0","enabledFeatures":["AsyncDNS","BitTorrent"]}}
        """
        let response = try JSONDecoder().decode(RPCResponse<Aria2VersionResponse>.self, from: json.data(using: .utf8)!)
        #expect(response.result?.version == "1.37.0")
        #expect(response.result?.enabledFeatures.count == 2)
    }

    @Test("Global stat response decodes")
    func globalStatResponseDecoding() throws {
        let json = """
        {"id":"1","jsonrpc":"2.0","result":{"downloadSpeed":"1024","uploadSpeed":"512","numActive":"2","numWaiting":"0","numStopped":"5","numStoppedTotal":"10"}}
        """
        let response = try JSONDecoder().decode(RPCResponse<Aria2GlobalStatResponse>.self, from: json.data(using: .utf8)!)
        let stat = try #require(response.result)
        #expect(stat.downloadSpeed == "1024")
        #expect(stat.uploadSpeed == "512")
        #expect(stat.numActive == "2")
    }

    @Test("Status response decodes")
    func statusResponseDecoding() throws {
        let json = """
        {"id":"1","jsonrpc":"2.0","result":{"gid":"2089b05ecca3d829","status":"active","totalLength":"1048576","completedLength":"524288","downloadSpeed":"65536","uploadSpeed":"0","files":[{"index":"1","path":"/Downloads/file.zip","length":"1048576","completedLength":"524288","uris":[{"uri":"https://example.com/file.zip","status":"used"}]}]}}
        """
        let response = try JSONDecoder().decode(RPCResponse<Aria2StatusResponse>.self, from: json.data(using: .utf8)!)
        let status = try #require(response.result)
        #expect(status.gid == "2089b05ecca3d829")
        #expect(status.status == "active")
        #expect(status.totalLength == "1048576")
        #expect(status.files?.count == 1)
        #expect(status.files?.first?.path == "/Downloads/file.zip")
    }

    @Test("RPC error response decodes")
    func rpcErrorResponseDecoding() throws {
        let json = """
        {"id":"1","jsonrpc":"2.0","error":{"code":-1,"message":"GID not found"}}
        """
        let response = try JSONDecoder().decode(RPCResponse<String>.self, from: json.data(using: .utf8)!)
        #expect(response.result == nil)
        #expect(response.error?.code == -1)
        #expect(response.error?.message == "GID not found")
    }

    @Test("AnyJSON encodes string")
    func anyJSONString() throws {
        let json = AnyJSON.string("hello")
        let data = try JSONEncoder().encode(json)
        #expect(String(data: data, encoding: .utf8) == "\"hello\"")
    }

    @Test("AnyJSON encodes array")
    func anyJSONArray() throws {
        let json = AnyJSON.array([.string("a"), .string("b")])
        let data = try JSONEncoder().encode(json)
        let decoded = try JSONSerialization.jsonObject(with: data) as? [String]
        #expect(decoded == ["a", "b"])
    }

    @Test("AnyJSON encodes dictionary")
    func anyJSONDictionary() throws {
        let json = AnyJSON.dictionary(["key": .string("value")])
        let data = try JSONEncoder().encode(json)
        let decoded = try JSONSerialization.jsonObject(with: data) as? [String: String]
        #expect(decoded == ["key": "value"])
    }
}
