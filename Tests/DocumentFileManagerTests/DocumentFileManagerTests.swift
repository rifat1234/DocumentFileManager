import XCTest
@testable import DocumentFileManager

final class DocumentFileManagerTests: XCTestCase {
    var documentFM:DocumentFileManager!
    let fm = FileManager.default
    let sampleFileName = "TestSample"
    let sampleFolderName = "TestFolder"
    let documentURL = URL.documentsDirectory
    var sampleFileData:Data!
    
    override func setUpWithError() throws {
        documentFM = DocumentFileManager.shared
        sampleFileData = "TestData".data(using: .utf8)!
        try removeAllFile()
    }

    override func tearDownWithError() throws {
        try removeAllFile()
    }

    func testURL() async throws {
        let url = try await documentFM.documentDiretoryURL
        XCTAssertEqual(url, URL.documentsDirectory)
    }

    func testFileNotExist() async throws {
        let url = documentURL.appending(path: sampleFileName)
        let isFileExist = await documentFM.fileExist(url)
        XCTAssertFalse(isFileExist)
    }
    
    func testFileExist() async throws {
        let url = documentURL.appending(path: sampleFileName)
        try sampleFileData.write(to: url)
        let isFileExist = await documentFM.fileExist(url)
        XCTAssertTrue(isFileExist)
    }
    
    func testDocumentDirWithoutContents() async throws {
        let contents = try await documentFM.getContents()
        XCTAssertTrue(contents.isEmpty)
    }
    
    func testDocumentDirWithContents() async throws {
        let url = documentURL.appending(path: sampleFileName)
        try sampleFileData.write(to: url)
        let contents = try await documentFM.getContents()
        XCTAssertEqual(contents, [sampleFileName])
    }
    
    func testDocumentDirWithoutContentsURL() async throws {
        let contents = try await documentFM.getContentsURL()
        XCTAssertTrue(contents.isEmpty)
    }
    
    func testDocumentDirWithContentsURL() async throws {
        let url = documentURL.appending(path: sampleFileName)
        try sampleFileData.write(to: url)
        let contents = try await documentFM.getContentsURL().map{$0.standardizedFileURL}
        XCTAssertEqual(contents, [url])
    }
    
    func testCopyWithoutReplace1() async throws {
        let newFileName = "NewSampleFile"
        let url = documentURL.appending(path: sampleFileName)
        let newURL = documentURL.appending(path: newFileName)
        try sampleFileData.write(to: url)
        
        try await documentFM.copyItem(at: url, to: newURL, replace: false)
        let contents = try getDocumentContents()
        
        XCTAssertEqual(contents.sorted(), [sampleFileName, newFileName].sorted())
    }
    
    func testCopyWithoutReplace2() async throws {
        let newFileName = "NewSampleFile"
        let url = documentURL.appending(path: sampleFileName)
        let newURL = documentURL.appending(path: newFileName)
        try sampleFileData.write(to: url)
        try sampleFileData.write(to: newURL)
        do {
            try await documentFM.copyItem(at: url, to: newURL, replace: false)
        } catch let error as NSError {
            XCTAssertEqual(error.code, 516)
        }
    }
    
    func testCopyWithReplace() async throws {
        let newFileName = "NewSampleFile"
        let url = documentURL.appending(path: sampleFileName)
        let newURL = documentURL.appending(path: newFileName)
        try sampleFileData.write(to: url)
        try sampleFileData.write(to: newURL)
        
        try await documentFM.copyItem(at: url, to: newURL)
        let contents = try getDocumentContents()
        
        XCTAssertEqual(contents.sorted(), [sampleFileName, newFileName].sorted())
    }
    
    func testRemove() async throws {
        let url = documentURL.appending(path: sampleFileName)
        try sampleFileData.write(to: url)
        try await documentFM.remove(url)
        let contents = try getDocumentContents()
        
        XCTAssertTrue(contents.isEmpty)
    }
    
    //MARK: - Folder
    func testGetFolderURL() async throws {
        let folderURL = documentURL.appending(path: sampleFolderName, directoryHint: .isDirectory)
        let url = try await documentFM.getFolderURL(sampleFolderName)
        XCTAssertEqual(url, folderURL)
    }
    
    func testCreateFolder() async throws {
        let url = try await documentFM.createFolder(sampleFolderName)
        let folderURLs = try getDocumentsFolders()
        XCTAssertTrue(url.isDirectory)
        XCTAssertEqual(folderURLs.map{$0.standardizedFileURL}, [url].map{$0.standardizedFileURL})
    }
    
    func testGetContentsOfFolder() async throws {
        let folderURL = try await documentFM.createFolder(sampleFolderName)
        let fileURL = folderURL.appending(path: sampleFileName)
        try sampleFileData.write(to: fileURL)
        
        let contents = try getContents(url: folderURL)
        XCTAssertEqual([sampleFileName], contents)
    }
    
    func testRemoveFolder() async throws {
        _ = try await documentFM.createFolder(sampleFolderName)
        try await documentFM.removeFolder(sampleFolderName)
        let folderURLs = try getDocumentsFolders()
        XCTAssertTrue(folderURLs.isEmpty)
    }
    
    func testDeleteFilesFromFolder() async throws {
        let folderURL = try await documentFM.createFolder(sampleFolderName)
        let fileURL = folderURL.appending(path: sampleFileName)
        try sampleFileData.write(to: fileURL)
        
        try await documentFM.deleteFiles(from: sampleFolderName)
    
        let contents = try getContents(url: folderURL)
        XCTAssertTrue(contents.isEmpty)
        
        let documentContents = try getContents(url: documentURL)
        XCTAssertEqual(documentContents, [sampleFolderName])
    }

}

extension DocumentFileManagerTests {
    private func removeAllFile() throws {
        let documentsUrl = URL.documentsDirectory
        let fileURLs = try FileManager.default.contentsOfDirectory(at: documentsUrl,
                                                                       includingPropertiesForKeys: nil,
                                                                       options: .skipsHiddenFiles)
        for fileURL in fileURLs {
            try FileManager.default.removeItem(at: fileURL)
        }
    }
    
    private func getContents(url: URL) throws -> [String] {
        try fm.contentsOfDirectory(atPath: url.path())
    }
    
    private func getDocumentContents() throws -> [String] {
        try getContents(url: documentURL)
    }
    
    private func getDocumentsFolders() throws -> [URL] {
        try fm.contentsOfDirectory(at: documentURL, includingPropertiesForKeys: nil).filter{$0.isDirectory}
    }
}

extension URL {
    var isDirectory: Bool {
       (try? resourceValues(forKeys: [.isDirectoryKey]))?.isDirectory == true
    }
}

