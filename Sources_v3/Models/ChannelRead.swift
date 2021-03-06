//
// Copyright © 2020 Stream.io Inc. All rights reserved.
//

import Foundation

public typealias ChatChannelRead = _ChatChannelRead<DefaultExtraData>

/// A type represnting a user's last read action on a channel.
public struct _ChatChannelRead<ExtraData: ExtraDataTypes> {
    /// The last time the user has read the channel.
    public let lastReadAt: Date
    
    /// Number of unread messages the user has in this channel.
    public let unreadMessagesCount: Int
    
    /// The user who read the channel.
    public let user: _ChatUser<ExtraData.User>
    
    init(
        lastReadAt: Date,
        unreadMessagesCount: Int,
        user: _ChatUser<ExtraData.User>
    ) {
        self.lastReadAt = lastReadAt
        self.unreadMessagesCount = unreadMessagesCount
        self.user = user
    }
}
