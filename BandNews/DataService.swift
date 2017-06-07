//
//  DataService.swift
//  GistIt
//
//  Created by Daniel Bonates on 27/03/17.
//  Copyright © 2017 Daniel Bonates. All rights reserved.
//

import Foundation

final class DataService {
    
    private static let dataFolder = "\(Bundle.main.bundleIdentifier!)"
    
    private static var basePath: String {
        return NSSearchPathForDirectoriesInDomains(.applicationSupportDirectory, .userDomainMask, true)
            .first!.appending("/\(DataService.dataFolder)/")
    }
    
    func cachePathFor(_ url: URL, id: Int? = nil) -> String {
        
        try? FileManager.default.createDirectory(
            atPath: DataService.basePath,
            withIntermediateDirectories: true,
            attributes: [:])
        
        if let id = id {
            return DataService.basePath.appending(url.lastPathComponent + "-\(id)")
        }
        return DataService.basePath.appending(url.lastPathComponent)
    }

    
    func load<T>(resource: Resource<T>, completion: @escaping (T?) -> ()) {
        (URLSession.shared.dataTask(with: resource.url, completionHandler: { data, response, error in
            guard error == nil else { print(error.debugDescription); return }
            guard
                let response = response as? HTTPURLResponse,
                response.statusCode == 200
                else {
                    print("request failed for\(resource.url.absoluteString). Reason: no server response or statusCode != 200.")
                    return
            }
            guard let data = data else { completion(nil); return }
            
//            let localURL = self.cachePathFor(resource.url, id: resource.id)
 
        
            completion(resource.parse(data))
        })).resume()
    }
    
    
    func loadLocal<T>(resource: Resource<T>, completion: @escaping (T?) -> ()) {
                
        let localURL = self.cachePathFor(resource.url, id: resource.id)
        
        guard let finalURL = URL(string: localURL) else { return }
        
        
        guard let data = try? Data(contentsOf: finalURL) else { completion(nil); return }
        
        completion(resource.parse(data))
    }
    
    
}
