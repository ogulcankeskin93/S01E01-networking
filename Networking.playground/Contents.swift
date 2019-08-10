//: To run this playground start a SimpleHTTPServer on the commandline like this:
//:
//: `python -m SimpleHTTPServer 8000`
//:
//: It will serve up the current directory, so make sure to be in the directory containing episodes.json

import UIKit
import PlaygroundSupport


typealias JSONDictionary = [String: AnyObject]

let url = NSURL(string: "http://localhost:80/episodes.json")!


struct Episode {
    let id: String
    let title: String
}

extension Episode {
    init?(dictionary: JSONDictionary) {
        guard let id = dictionary["id"] as? String,
            let title = dictionary["title"] as? String else { return nil }
        self.id = id
        self.title = title
    }
}


struct Media {}


struct Resource<A> {
    let url: NSURL
    let parse: (Data) -> A?
}

extension Resource {
    init(url: NSURL, parseJSON: @escaping (Any) -> A?) {
        self.url = url
        self.parse = { data in
            let json = try? JSONSerialization.jsonObject(with: data, options: [])
            return json.flatMap(parseJSON)
        }
    }
}


extension Episode {
    static let all = Resource<[Episode]>(url: url, parseJSON: { json in
        guard let dictionaries = json as? [JSONDictionary] else { return nil }
        return dictionaries.compactMap(Episode.init)
    })
}


final class Webservice {
    func load<A>(resource: Resource<A>, completion: @escaping (A?) -> ()) {
        URLSession.shared.dataTask(with: resource.url as URL) { data, _, _ in
            guard let data = data else {
                completion(nil)
                return
            }
            completion(resource.parse(data))
            }.resume()
    }
}


PlaygroundPage.current.needsIndefiniteExecution = true

Webservice().load(resource: Episode.all) { result in
    guard let result = result else {return}
    result.forEach {
        print($0.id)
        print($0.title)
    }
}
