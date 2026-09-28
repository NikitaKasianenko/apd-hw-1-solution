import Foundation

public enum StudyCategory: String, Codable, CaseIterable {
    case reading, practice, project
}

public enum StudyPlanError: Error, Equatable {
    case blankTitle
    case nonPositiveEstimatedMinutes
    case duplicateID(String)
    case unknownID(String)
}

public struct StudyItem: Codable, Equatable {
    public let id: String
    public let title: String
    public let estimatedMinutes: Int
    public let category: StudyCategory
    public private(set) var isCompleted: Bool

    public init(
        id: String,
        title: String,
        estimatedMinutes: Int,
        category: StudyCategory,
        isCompleted: Bool = false
    ) throws {
        if title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            throw StudyPlanError.blankTitle
        }
        
        if estimatedMinutes <= 0 {
            throw StudyPlanError.nonPositiveEstimatedMinutes
        }
        
        self.id = id
        self.title = title
        self.estimatedMinutes = estimatedMinutes
        self.category = category
        self.isCompleted = isCompleted
    }
    
    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let id = try container.decode(String.self, forKey: .id)
        let title = try container.decode(String.self, forKey: .title)
        let estimatedMinutes = try container.decode(Int.self, forKey: .estimatedMinutes)
        let category = try container.decode(StudyCategory.self, forKey: .category)
        let isCompleted = try container.decodeIfPresent(Bool.self, forKey: .isCompleted) ?? false
        
        try self.init(id: id, title: title, estimatedMinutes: estimatedMinutes, category: category, isCompleted: isCompleted)
        
    }
}

public struct StudyPlan: Codable, Equatable {
    public private(set) var items: [StudyItem]

    public init(items: [StudyItem]) throws {
        
        var seen = Set<String>()
        
        for item in items{
            if seen.contains(item.id){
                throw StudyPlanError.duplicateID(item.id)
            }
            seen.insert(item.id)
        }
        
        self.items = items.sorted {($0.title,$0.id) < ($1.title,$1.id)}
        
    }
    
    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let items = try container.decode([StudyItem].self, forKey: .items)
        try self.init(items: items)
        
    }
    

    public static func decode(from data: Data) throws -> StudyPlan {
        let items = try JSONDecoder().decode([StudyItem].self, from: data)
        return try StudyPlan(items: items)
    }

    public func items(in category: StudyCategory) -> [StudyItem] {
        return items.filter {item in item.category == category}
    }

    public func incompleteMinutes() -> Int {
        var total = 0
        for item in items where !item.isCompleted{
            total += item.estimatedMinutes
        }
        return total
    }

    public mutating func markCompleted(id: String) throws {
        
        guard let index = items.firstIndex(where:{ $0.id == id }) else{
            throw StudyPlanError.unknownID(id)
        }
        
        let item = items[index]
        if item.isCompleted{
            return
        }
        
        items[index] = try StudyItem(id: item.id, title: item.title, estimatedMinutes: item.estimatedMinutes, category: item.category, isCompleted: true)
    }

    public mutating func importMerging(_ importedItems: [StudyItem]) throws {
        
        var seen = Set<String>()
        for importedItem in importedItems {
            if seen.contains(importedItem.id) {
                throw StudyPlanError.duplicateID(importedItem.id)
            }
            seen.insert(importedItem.id)
        }
        
        var importedById: [String:StudyItem] = [:]
        
        for item in importedItems{
            importedById[item.id] = item
        }
        
        var result: [StudyItem] = []
        for item in items {
            if let replacement = importedById[item.id] {
                result.append(replacement)
            } else {
                result.append(item)
            }
        }
        
        let oldIDs = Set(items.map{$0.id})
        
        let newItems = importedItems.filter { item in !oldIDs.contains(item.id) }.sorted { $0.id < $1.id }
        
        result.append(contentsOf: newItems)
        items = result
        
    }
}
