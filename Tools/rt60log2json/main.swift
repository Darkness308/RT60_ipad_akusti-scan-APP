import Foundation

@main
struct CLI {
    static func main() {
        let args = CommandLine.arguments
        guard args.count >= 2 else { fputs("Usage: rt60log2json <input.txt> -o <output.json>\n", stderr); exit(2) }
        var input: String?
        var output: String?
        var i = 1
        while i < args.count {
            let a = args[i]
            if a == "-o" && i+1 < args.count { output = args[i+1]; i += 2; continue }
            if input == nil { input = a } else { i += 1 }
            i += 1
        }
        guard let inPath = input, let outPath = output else {
            fputs("Usage: rt60log2json <input.txt> -o <output.json>\n", stderr); exit(2)
        }
        do {
            let text = try String(contentsOfFile: inPath, encoding: .utf8)
            let model = try RT60LogParser().parse(text: text, sourceFile: (inPath as NSString).lastPathComponent)
            let data = try JSONEncoder().encode(model)
            guard let pretty = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
                fputs("Error: Top-level JSON is not a dictionary\n", stderr)
                exit(1)
            }
            let outData = try JSONSerialization.data(withJSONObject: pretty, options: [.prettyPrinted, .sortedKeys])
            try outData.write(to: URL(fileURLWithPath: outPath))
            print("OK: wrote \(outPath)")
            exit(0)
        } catch {
            fputs("Error: \(error)\n", stderr)
            exit(1)
        }
    }
}