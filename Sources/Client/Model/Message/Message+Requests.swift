//
//  Message+Requests.swift
//  StreamChatCore
//
//  Created by Alexey Bukhtin on 10/01/2020.
//  Copyright © 2020 Stream.io Inc. All rights reserved.
//

import Foundation

public extension Message {
    
    /// Delete the message.
    /// - Parameter completion: a completion block with `MessageResponse`.
    @discardableResult
    func delete(client: Client = .shared, _ completion: @escaping Client.Completion<MessageResponse>) -> URLSessionTask {
        return client.request(endpoint: .deleteMessage(self), completion)
    }
    
    /// Send a request for reply messages.
    /// - Parameters:
    ///   - pagination: a pagination (see `Pagination`).
    ///   - completion: a completion block with `[Message]`.
    @discardableResult
    func replies(pagination: Pagination,
                 client: Client = .shared,
                 _ completion: @escaping Client.Completion<[Message]>) -> URLSessionTask {
        let completion = doAfter(completion) { messages in
            self.add(repliesToDatabase: messages)
        }
        
        return client.request(endpoint: .replies(self, pagination)) { (result: Result<MessagesResponse, ClientError>) in
            completion(result.map({ $0.messages }))
        }
    }
    
    // MARK: - Reactions
    
    /// Add a reaction to the message.
    /// - Parameters:
    ///   - reactionType: a reaction type, e.g. like.
    ///   - completion: a completion block with `MessageResponse`.
    @discardableResult
    func addReaction(_ reactionType: ReactionType,
                     client: Client = .shared,
                     _ completion: @escaping Client.Completion<MessageResponse>) -> URLSessionTask {
        return client.request(endpoint: .addReaction(reactionType, self), completion)
    }
    
    /// Delete a reaction to the message.
    /// - Parameters:
    ///   - reactionType: a reaction type, e.g. like.
    ///   - completion: a completion block with `MessageResponse`.
    @discardableResult
    func deleteReaction(_ reactionType: ReactionType,
                        client: Client = .shared,
                        _ completion: @escaping Client.Completion<MessageResponse>) -> URLSessionTask {
        return client.request(endpoint: .deleteReaction(reactionType, self), completion)
    }
    
    // MARK: Flag Message
    
    /// Flag a message.
    /// - Parameter completion: a completion block with `FlagMessageResponse`.
    @discardableResult
    func flag(client: Client = .shared, _ completion: @escaping Client.Completion<FlagMessageResponse>) -> URLSessionTask {
        if user.isCurrent {
            completion(.success(.init(messageId: id, created: Date(), updated: Date())))
            return .empty
        }
        
        let completion = doAfter(completion) { _ in
            Message.flaggedIds.insert(self.id)
        }
        
        return flagUnflagMessage(endpoint: .flagMessage(self), client: client, completion)
    }
    
    /// Unflag a message.
    /// - Parameter completion: a completion block with `FlagMessageResponse`.
    @discardableResult
    func unflag(client: Client = .shared, _ completion: @escaping Client.Completion<FlagMessageResponse>) -> URLSessionTask {
        if user.isCurrent {
            completion(.success(.init(messageId: id, created: Date(), updated: Date())))
            return .empty
        }
        
        let completion = doAfter(completion) { _ in
            if let index = Message.flaggedIds.firstIndex(where: { $0 == self.id }) {
                Message.flaggedIds.remove(at: index)
            }
        }
        
        return flagUnflagMessage(endpoint: .unflagMessage(self), client: client, completion)
    }
    
    private func flagUnflagMessage(endpoint: Endpoint,
                                   client: Client,
                                   _ completion: @escaping Client.Completion<FlagMessageResponse>) -> URLSessionTask {
        return client.request(endpoint: endpoint) { (result: Result<FlagMessageResponse, ClientError>) in
            let result = result.catchError { error in
                if case .responseError(let clientResponseError) = error,
                    clientResponseError.message.contains("flag already exists") {
                    return .success(.init(messageId: self.id, created: Date(), updated: Date()))
                }
                
                return .failure(error)
            }
            
            completion(result)
        }
    }
}