//
// Copyright © 2020 Stream.io Inc. All rights reserved.
//

import Foundation

/// A convenience `_ChatChannel` typealias with no additional channel data.
public typealias ChatChannel = _ChatChannel<DefaultExtraData>

public struct _ChatChannel<ExtraData: ExtraDataTypes> {
    /// A channel type + id.
    public let cid: ChannelId
    
    /// The date of the last message in the channel.
    public let lastMessageAt: Date?
    
    /// The date when the channel was created.
    public let createdAt: Date
    
    /// The date when the channel was updated.
    public let updatedAt: Date
    
    /// If the channel weas deleted, this field contains the date of the deletion.
    public let deletedAt: Date?
    
    /// The user which created the channel.
    public let createdBy: _ChatUser<ExtraData.User>?
    
    /// A config.
    public let config: ChannelConfig
    
    /// Checks if the channel is frozen.
    public let isFrozen: Bool
    
    /// A list of channel members.
    public let members: Set<_ChatChannelMember<ExtraData.User>>
    
    /// A list of typing channel members.
    public let currentlyTypingMembers: Set<_ChatChannelMember<ExtraData.User>>
    
    /// A list of channel watchers.
    public let watchers: Set<_ChatUser<ExtraData.User>>
    
    /// The team the channel belongs to. You need to enable multi-tenancy if you want to use this, else it'll be nil.
    /// Refer to [docs](https://getstream.io/chat/docs/multi_tenant_chat/?language=swift) for more info.
    public let team: String
    
    /// Returns the current unread count.
    public let unreadCount: ChannelUnreadCount
    
    /// Online watchers in the channel.
    public let watcherCount: Int
    
    /// Members in the channel.
    public let memberCount: Int
    
    /// An option to enable ban users.
    public let banEnabling: BanEnabling
    
    /// Checks if the channel is watching by the client.
    public let isWatched: Bool
    
    // TODO: refactor comment and add latestMessages limit mention
    /// Latest messages present on the channel.
    public let latestMessages: [_ChatMessage<ExtraData>]
    
    /// Read states of the users for this channel.
    public let reads: [_ChatChannelRead<ExtraData>]
    
    public let extraData: ExtraData.Channel
    
    // MARK: - Internal
    
    /// A helper variable to cache the result of the filter for only banned members.
    //  lazy var bannedMembers: Set<_ChatChannelMember<ExtraData.User>> = Set(self.members.filter { $0.isBanned })
    
    /// A list of users to invite in the channel.
    let invitedMembers: Set<_ChatChannelMember<ExtraData.User>> // TODO: Why is this not public?
    
    init(
        cid: ChannelId,
        lastMessageAt: Date? = nil,
        createdAt: Date = .init(),
        updatedAt: Date = .init(),
        deletedAt: Date? = nil,
        createdBy: _ChatUser<ExtraData.User>? = nil,
        config: ChannelConfig = .init(),
        isFrozen: Bool = false,
        members: Set<_ChatChannelMember<ExtraData.User>> = [],
        currentlyTypingMembers: Set<_ChatChannelMember<ExtraData.User>> = [],
        watchers: Set<_ChatUser<ExtraData.User>> = [],
        team: String = "",
        unreadCount: ChannelUnreadCount = .noUnread,
        watcherCount: Int = 0,
        memberCount: Int = 0,
        banEnabling: BanEnabling = .disabled,
        isWatched: Bool = false,
        reads: [_ChatChannelRead<ExtraData>] = [],
        extraData: ExtraData.Channel,
        invitedMembers: Set<_ChatChannelMember<ExtraData.User>> = [],
        latestMessages: [_ChatMessage<ExtraData>] = []
    ) {
        self.cid = cid
        self.lastMessageAt = lastMessageAt
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.deletedAt = deletedAt
        self.createdBy = createdBy
        self.config = config
        self.isFrozen = isFrozen
        self.members = members
        self.currentlyTypingMembers = currentlyTypingMembers
        self.watchers = watchers
        self.team = team
        self.unreadCount = unreadCount
        self.watcherCount = watcherCount
        self.memberCount = memberCount
        self.banEnabling = banEnabling
        self.isWatched = isWatched
        self.reads = reads
        self.extraData = extraData
        self.invitedMembers = invitedMembers
        self.latestMessages = latestMessages
    }
}

extension _ChatChannel {
    /// A channel type.
    public var type: ChannelType { cid.type }
    
    /// Check if the channel was deleted.
    public var isDeleted: Bool { deletedAt != nil }
    
    /// Checks if read events evalable for the current user.
    public var readEventsEnabled: Bool { /* config.readEventsEnabled && members.contains(Member.current) */ fatalError() }
    
    /// Checks if the channel is direct message type between 2 users.
    public var isDirectMessage: Bool { cid.id.hasPrefix("!members") && members.count == 2 }
    
    /// Checks if the current status of the channel is unread.
    public var isUnread: Bool { unreadCount.messages > 0 }
    
    /// Checks for the channel data encoding is empty.
    var isEmpty: Bool { /* extraData == nil && members.isEmpty && invitedMembers.isEmpty */ fatalError() }
}

/// Additional data fields `ChannelModel` can be extended with. You can use it to store your custom data related to a channel.
public protocol ChannelExtraData: ExtraData {}

/// A type-erased version of `ChannelModel<CustomData>`. Not intended to be used directly.
public protocol AnyChannel {}
extension _ChatChannel: AnyChannel {}

extension _ChatChannel: Hashable {
    public static func == (lhs: _ChatChannel<ExtraData>, rhs: _ChatChannel<ExtraData>) -> Bool {
        lhs.cid == rhs.cid
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(cid)
    }
}

/// An unread counts for a channel.
public struct ChannelUnreadCount: Decodable, Equatable {
    public static let noUnread = ChannelUnreadCount(messages: 0, mentionedMessages: 0)
    public internal(set) var messages: Int
    public internal(set) var mentionedMessages: Int
}
