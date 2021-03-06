//
// Copyright © 2020 Stream.io Inc. All rights reserved.
//

import StreamChatClient
import SwiftUI

@available(iOS 14, *)
struct ChatView: View {
    /// The `ChannelController` used to interact with this channel. Will be synchornized in `onAppear`.
    @State var channel: ChatChannelController.ObservableObject
    /// The `text` written in the message composer
    @State var text: String = ""
    /// Binding for message actions ActionSheet
    @State var actionSheetTrigger: Bool = false
    /// Message being edited
    @State var editingMessage: ChatMessage?

    /// User action
    @State var userActionTrigger: Bool = false
    @State var userAction: ((String) -> Void)?

    var body: some View {
        VStack {
            self.messageList().layoutPriority(1)
            self.composerView()
        }
        /// Channel ActionSheet presenter.
        .actionSheet(isPresented: $actionSheetTrigger, content: self.actionSheet)
        /// User action alert
        .alert(isPresented: $userActionTrigger, TextAlert(title: "User Id", placeholder: "steep-moon-9", action: {
            self.userAction?($0 ?? "steep-moon-9")
            self.userAction = nil
        }))
        /// Set title to channel's name
        .navigationBarTitle(
            Text(channel.channel.flatMap(createTypingMemberString) ?? channel.channel?.extraData.name ?? "Unnamed Channel"),
            displayMode: .inline
        )
        /// Channel actions button
        .navigationBarItems(
            trailing: Button(action: { self.actionSheetTrigger = true }) {
                Image(systemName: "ellipsis")
            }
        )
        /// Initialize the `ChannelController`
        .onAppear(perform: { self.channel.controller.synchronize() })
    }
    
    func messageList() -> some View {
        List(channel.messages, id: \.self) { message in
            self.messageView(for: message)
                .onLongPressGesture { self.actionSheetTrigger = true; self.editingMessage = message }
        }
        .scaleEffect(x: 1, y: -1, anchor: .center)
        .offset(x: 0, y: 2)
    }
    
    func messageView(for message: ChatMessage) -> some View {
        let username = message.author.extraData.name ?? message.author.id
        let text: Text
        
        switch message.type {
        case .deleted:
            text = Text("❌ the message was deleted")
        case .error:
            text = Text("⚠️ something wrong happened")
        default:
            text = (Text(username).bold().foregroundColor(.forUsername(username)) + Text(" \(message.text)"))
        }
        
        return text
            /// Inverted list workaround
            .scaleEffect(x: 1, y: -1, anchor: .center)
            /// Load next more messages when the last is shown
            .onAppear {
                if (self.channel.messages.last == message) {
                    self.channel.controller.loadPreviousMessages()
                }
            }
    }
    
    func composerView() -> some View {
        let textBinding = Binding(
            get: { self.text },
            set: { newValue in
                DispatchQueue.main.async {
                    self.text = newValue
                    self.didKeystroke()
                }
            }
        )
        
        return HStack {
            ZStack {
                if text.isEmpty {
                    Text("Type a message")
                        .foregroundColor(.secondary)
                        .padding(.all, 8)
                        .frame(maxWidth: .infinity, alignment: .leading)
                } else {
                    Text(text) // hack to auto expand the composer (TextEditor alone won't do it)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.all, 8)
                        .opacity(0)
                }
                
                TextEditor(text: textBinding).background(Color.clear).onAppear {
                    UITextView.appearance().backgroundColor = .clear
                }
            }
            Button(action: self.send) {
                Image(systemName: "arrow.up.circle.fill")
            }
        }.padding()
    }
    
    func send() {
        guard let channelId = channel.channel?.cid else {
            return
        }
        
        if let editingMessage = self.editingMessage {
            let controller = channel.controller.client.messageController(cid: channelId, messageId: editingMessage.id)
            controller.editMessage(text: text)
            self.editingMessage = nil
        } else {
            channel.controller.createNewMessage(text: text)
        }

        text = ""
    }
    
    /// Action sheet with channel actions
    func actionSheet() -> ActionSheet {
        if let message = editingMessage {
            let messageController = channel.controller.client.messageController(cid: channel.channel!.cid, messageId: message.id)
            return ActionSheet(title: Text("Message Actions"), message: Text(""), buttons: [
                .default(Text("Edit"), action: { self.editingMessage = message; self.text = message.text }),
                .destructive(Text("Delete")) { messageController.deleteMessage(); self.editingMessage = nil },
                .cancel { self.editingMessage = nil }
            ])
        } else {
            return ActionSheet(title: Text("Channel Actions"), message: Text(""), buttons: [
                .default(
                    Text("Add Member"), action: {
                        self.userAction = { self.channel.controller.addMembers(userIds: [$0]) }
                        self.userActionTrigger = true
                    }
                ),
                .default(
                    Text("Remove Member"), action: {
                        self.userAction = { self.channel.controller.removeMembers(userIds: [$0]) }
                        self.userActionTrigger = true
                    }
                ),
                .cancel()
            ])
        }
    }
    
    private func didKeystroke() {
        channel.controller.keystroke()
    }
    
    private func didStopTyping() {
        channel.controller.stopTyping()
    }
}
