//
//  remoteImage.swift
//  Code App
//
//  Created by Ken Chung on 5/12/2020.
//

import SwiftUI
import Foundation

struct RemoteImage: View {
    private enum LoadState {
        case loading, success, failure
    }

    private class Loader: ObservableObject {
        private static let cache = NSCache<NSString, NSData>()

        var data = Data()
        var state = LoadState.loading

        init(url: String) {
            let cacheKey = url as NSString
            if let cached = Loader.cache.object(forKey: cacheKey) {
                self.data = cached as Data
                self.state = .success
                return
            }

            guard let parsedURL = URL(string: url) else {
                self.state = .failure
                return
            }

            URLSession.shared.dataTask(with: parsedURL) { data, response, error in
                if let data = data, data.count > 0 {
                    Loader.cache.setObject(data as NSData, forKey: cacheKey)
                    self.data = data
                    self.state = .success
                } else {
                    self.state = .failure
                }

                DispatchQueue.main.async {
                    self.objectWillChange.send()
                }
            }.resume()
        }
    }

    @StateObject private var loader: Loader

    var body: some View {
        Group {
            switch loader.state {
            case .loading, .failure:
                Rectangle()
                    .fill(.clear)
            default:
                if let image = UIImage(data: loader.data) {
                    Image(uiImage: image).resizable()
                } else {
                    Rectangle()
                        .fill(.clear)
                }
            }
        }

    }

    init(
        url: String
    ) {
        _loader = StateObject(wrappedValue: Loader(url: url))
    }
}
