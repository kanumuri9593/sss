import WidgetKit
import SwiftUI

/// App Group identifier for data sharing
let appGroupId = "group.com.example.sss"

// MARK: - Data Models

struct ContainerData: Codable, Identifiable {
    let id: String
    let name: String
    let type: String
    let itemCount: Int
    let deepLink: String
    
    var typeIcon: String {
        switch type {
        case "box": return "📦"
        case "bag": return "👜"
        case "drawer": return "🗄️"
        default: return "📦"
        }
    }
    
    var typeSystemImage: String {
        switch type {
        case "box": return "shippingbox.fill"
        case "bag": return "bag.fill"
        case "drawer": return "tray.2.fill"
        default: return "shippingbox.fill"
        }
    }
}

// MARK: - Widget Entry

struct SSSWidgetEntry: TimelineEntry {
    let date: Date
    let containerCount: Int
    let itemCount: Int
    let recentContainers: [ContainerData]
    let lastUpdated: String
}

// MARK: - Timeline Provider

struct SSSProvider: TimelineProvider {
    func placeholder(in context: Context) -> SSSWidgetEntry {
        SSSWidgetEntry(
            date: Date(),
            containerCount: 0,
            itemCount: 0,
            recentContainers: [],
            lastUpdated: ""
        )
    }
    
    func getSnapshot(in context: Context, completion: @escaping (SSSWidgetEntry) -> Void) {
        let entry = loadWidgetData()
        completion(entry)
    }
    
    func getTimeline(in context: Context, completion: @escaping (Timeline<SSSWidgetEntry>) -> Void) {
        let entry = loadWidgetData()
        
        // Update every 15 minutes
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 15, to: Date())!
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        
        completion(timeline)
    }
    
    private func loadWidgetData() -> SSSWidgetEntry {
        let userDefaults = UserDefaults(suiteName: appGroupId)
        
        let containerCount = userDefaults?.integer(forKey: "containerCount") ?? 0
        let itemCount = userDefaults?.integer(forKey: "itemCount") ?? 0
        let lastUpdated = userDefaults?.string(forKey: "lastUpdated") ?? ""
        
        var recentContainers: [ContainerData] = []
        if let containersJson = userDefaults?.string(forKey: "recentContainers"),
           let data = containersJson.data(using: .utf8) {
            recentContainers = (try? JSONDecoder().decode([ContainerData].self, from: data)) ?? []
        }
        
        return SSSWidgetEntry(
            date: Date(),
            containerCount: containerCount,
            itemCount: itemCount,
            recentContainers: recentContainers,
            lastUpdated: lastUpdated
        )
    }
}

// MARK: - Quick Search Widget View (Small)

struct QuickSearchWidgetView: View {
    var entry: SSSWidgetEntry
    @Environment(\.widgetFamily) var family
    
    var body: some View {
        ZStack {
            ContainerRelativeShape()
                .fill(LinearGradient(
                    colors: [Color.blue.opacity(0.8), Color.purple.opacity(0.6)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ))
            
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "magnifyingglass")
                        .font(.title2)
                        .foregroundColor(.white)
                    Spacer()
                    Image(systemName: "qrcode.viewfinder")
                        .font(.title3)
                        .foregroundColor(.white.opacity(0.8))
                }
                
                Spacer()
                
                Text("SSS")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                HStack(spacing: 4) {
                    Image(systemName: "shippingbox.fill")
                        .font(.caption2)
                    Text("\(entry.containerCount)")
                        .font(.caption)
                        .fontWeight(.semibold)
                    
                    Spacer().frame(width: 8)
                    
                    Image(systemName: "tag.fill")
                        .font(.caption2)
                    Text("\(entry.itemCount)")
                        .font(.caption)
                        .fontWeight(.semibold)
                }
                .foregroundColor(.white.opacity(0.9))
            }
            .padding()
        }
        .widgetURL(URL(string: "sss://search"))
    }
}

// MARK: - Recent Containers Widget View (Medium)

struct RecentContainersWidgetView: View {
    var entry: SSSWidgetEntry
    
    var body: some View {
        ZStack {
            ContainerRelativeShape()
                .fill(Color(.systemBackground))
            
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Recent Containers")
                        .font(.headline)
                        .foregroundColor(.primary)
                    Spacer()
                    Image(systemName: "arrow.right.circle.fill")
                        .foregroundColor(.blue)
                }
                
                if entry.recentContainers.isEmpty {
                    Spacer()
                    HStack {
                        Spacer()
                        VStack(spacing: 4) {
                            Image(systemName: "shippingbox")
                                .font(.largeTitle)
                                .foregroundColor(.gray)
                            Text("No containers yet")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                    }
                    Spacer()
                } else {
                    HStack(spacing: 12) {
                        ForEach(entry.recentContainers.prefix(3)) { container in
                            Link(destination: URL(string: container.deepLink)!) {
                                VStack(spacing: 4) {
                                    ZStack {
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(Color.blue.opacity(0.1))
                                            .frame(width: 50, height: 50)
                                        
                                        Image(systemName: container.typeSystemImage)
                                            .font(.title2)
                                            .foregroundColor(.blue)
                                    }
                                    
                                    Text(container.name)
                                        .font(.caption2)
                                        .fontWeight(.medium)
                                        .foregroundColor(.primary)
                                        .lineLimit(1)
                                    
                                    Text("\(container.itemCount) items")
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                }
                                .frame(maxWidth: .infinity)
                            }
                        }
                    }
                }
            }
            .padding()
        }
        .widgetURL(URL(string: "sss://containers"))
    }
}

// MARK: - Stats Widget View (Large)

struct StatsWidgetView: View {
    var entry: SSSWidgetEntry
    
    var body: some View {
        ZStack {
            ContainerRelativeShape()
                .fill(LinearGradient(
                    colors: [Color.indigo.opacity(0.9), Color.purple.opacity(0.7)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ))
            
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    VStack(alignment: .leading) {
                        Text("SSS Storage")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                        Text("Your inventory at a glance")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.8))
                    }
                    Spacer()
                    Image(systemName: "shippingbox.fill")
                        .font(.largeTitle)
                        .foregroundColor(.white.opacity(0.3))
                }
                
                Spacer()
                
                // Stats Grid
                HStack(spacing: 16) {
                    StatCard(icon: "shippingbox.fill", value: "\(entry.containerCount)", label: "Containers")
                    StatCard(icon: "tag.fill", value: "\(entry.itemCount)", label: "Items")
                }
                
                Spacer()
                
                // Recent containers
                if !entry.recentContainers.isEmpty {
                    Text("Recent")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.white.opacity(0.9))
                    
                    HStack(spacing: 8) {
                        ForEach(entry.recentContainers.prefix(4)) { container in
                            Link(destination: URL(string: container.deepLink)!) {
                                HStack(spacing: 4) {
                                    Image(systemName: container.typeSystemImage)
                                        .font(.caption)
                                    Text(container.name)
                                        .font(.caption2)
                                        .lineLimit(1)
                                }
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.white.opacity(0.2))
                                .cornerRadius(8)
                                .foregroundColor(.white)
                            }
                        }
                    }
                }
            }
            .padding()
        }
        .widgetURL(URL(string: "sss://stats"))
    }
}

struct StatCard: View {
    let icon: String
    let value: String
    let label: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Image(systemName: icon)
                    .font(.caption)
                Text(value)
                    .font(.title)
                    .fontWeight(.bold)
            }
            Text(label)
                .font(.caption2)
        }
        .foregroundColor(.white)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color.white.opacity(0.15))
        .cornerRadius(12)
    }
}

// MARK: - Widget Definitions

struct SSSQuickSearchWidget: Widget {
    let kind: String = "SSSQuickSearchWidget"
    
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: SSSProvider()) { entry in
            QuickSearchWidgetView(entry: entry)
        }
        .configurationDisplayName("Quick Search")
        .description("Quickly access SSS search and scan features")
        .supportedFamilies([.systemSmall])
    }
}

struct SSSRecentContainersWidget: Widget {
    let kind: String = "SSSRecentContainersWidget"
    
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: SSSProvider()) { entry in
            RecentContainersWidgetView(entry: entry)
        }
        .configurationDisplayName("Recent Containers")
        .description("Quick access to your recent containers")
        .supportedFamilies([.systemMedium])
    }
}

struct SSSStatsWidget: Widget {
    let kind: String = "SSSStatsWidget"
    
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: SSSProvider()) { entry in
            StatsWidgetView(entry: entry)
        }
        .configurationDisplayName("Storage Stats")
        .description("Overview of your storage inventory")
        .supportedFamilies([.systemLarge])
    }
}

// MARK: - Widget Bundle

@main
struct SSSWidgetBundle: WidgetBundle {
    var body: some Widget {
        SSSQuickSearchWidget()
        SSSRecentContainersWidget()
        SSSStatsWidget()
    }
}

// MARK: - Previews

struct SSSWidget_Previews: PreviewProvider {
    static var previews: some View {
        let sampleContainers = [
            ContainerData(id: "1", name: "Winter Clothes", type: "box", itemCount: 12, deepLink: "sss://container/1"),
            ContainerData(id: "2", name: "Tools", type: "drawer", itemCount: 8, deepLink: "sss://container/2"),
            ContainerData(id: "3", name: "Travel", type: "bag", itemCount: 5, deepLink: "sss://container/3"),
        ]
        
        let entry = SSSWidgetEntry(
            date: Date(),
            containerCount: 15,
            itemCount: 87,
            recentContainers: sampleContainers,
            lastUpdated: "2025-01-02T10:30:00Z"
        )
        
        Group {
            QuickSearchWidgetView(entry: entry)
                .previewContext(WidgetPreviewContext(family: .systemSmall))
                .previewDisplayName("Quick Search")
            
            RecentContainersWidgetView(entry: entry)
                .previewContext(WidgetPreviewContext(family: .systemMedium))
                .previewDisplayName("Recent Containers")
            
            StatsWidgetView(entry: entry)
                .previewContext(WidgetPreviewContext(family: .systemLarge))
                .previewDisplayName("Stats")
        }
    }
}
