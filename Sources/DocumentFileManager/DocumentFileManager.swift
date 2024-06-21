// The Swift Programming Language
// https://docs.swift.org/swift-book

import Foundation

public actor DocumentFileManager {
    static let shared = DocumentFileManager()
    private init() {}
    
    var fm: FileManager {
        FileManager.default
    }
    
    var documentDiretoryURL:URL {
        get throws {
            URL.documentsDirectory
        }
    }
    
    func fileExist(_ url: URL) -> Bool {
        fm.fileExists(atPath: url.relativePath)
    }
    
    func getContentsURL() throws -> [URL] {
        try getContentsURL(of: documentDiretoryURL)
    }
    
    func getContents() throws -> [String] {
        try getContentsName(of: documentDiretoryURL)
    }
    
    func copyItem(at oldURL:URL, to url: URL, replace: Bool = true) throws {
        if replace {
            try remove(url)
        }
        try FileManager.default.copyItem(at: oldURL, to: url)
    }
    
    func remove(_ url: URL) throws {
        if fileExist(url) {
            try fm.removeItem(at: url)
        }
    }
    
    //MARK: - Folder
    func getFolderURL(_ folderName: String) throws -> URL {
        return try documentDiretoryURL.appending(path: folderName, directoryHint: .isDirectory)
    }
    
    @discardableResult
    func createFolder(_ folderName: String) throws -> URL {
        let folderURL = try getFolderURL(folderName)
        if !fileExist(folderURL) {
            try fm.createDirectory(at: folderURL, withIntermediateDirectories: true)
        }
        
        return folderURL
    }
    
    func getContents(of folderName: String) throws ->[String] {
        let folderURL = try getFolderURL(folderName)
        return try getContentsName(of: folderURL)
    }
    
    func removeFolder(_ folderName: String) throws {
        let folderURL = try getFolderURL(folderName)
        try remove(folderURL)
    }
    
    func deleteFiles(from folderName: String) throws {
        let folderURL = try getFolderURL(folderName)
        let urls = try getContentsURL(of: folderURL)
        try urls.forEach{ try remove($0) }
    }
    
    //MARK: - Private
    private func getContentsName(of url: URL) throws ->[String] {
        try fm.contentsOfDirectory(atPath: url.relativePath)
    }
    
    private func getContentsURL(of url: URL) throws -> [URL] {
        try fm.contentsOfDirectory(at: url, includingPropertiesForKeys: nil)
    }
    
}
