//
//  ChatLogViewController.swift
//  Codeup
//
//  Created by Geoff Arroyo on 4/28/21.
//

import UIKit
import Firebase

class ChatLogViewController: UICollectionViewController, UICollectionViewDelegateFlowLayout {
    
    private let cellId = "cellId"
    
    var activeUser: UserProfile?
    
    var conversationsRef: DatabaseReference?
    
    var conversationOfFriend: Conversation?
    
    var friendProfile: UserProfile? {
        didSet {
            guard let unwrappedFriendProfile = self.friendProfile else {
                print("Not a valid friend profile constructor, won't set UI title name for the Chat Log view controller.")
                return
            }
            navigationItem.title = unwrappedFriendProfile.firstName + " " + unwrappedFriendProfile.lastName
        }
    }
    
    var conversation: Conversation? {
        didSet {
            guard let unwrappedConversation = self.conversation else {
                print("Not a valid conversation constructor, won't set messages array property in Chat Log view controller.")
                return
            }
            self.messages = unwrappedConversation.messages
        }
    }
    
    var messages: [Message]?
    
    let messageInputContainerView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.white
        return view
    }()
    
    let inputTextField: UITextField = {
        let textField = UITextField()
        textField.placeholder = "Enter message.."
        return textField
    }()
    
    let sendButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Send", for: .normal)
        button.setTitleColor(UIColor(red: 0, green: 137/255, blue: 249/255, alpha: 1), for: .normal)
        button.titleLabel?.font = UIFont.boldSystemFont(ofSize: 16)
        button.addTarget(self, action: #selector(handleSend), for: .touchUpInside)
        return button
    }()
    
    var bottomConstraint: NSLayoutConstraint?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.collectionView.backgroundColor = UIColor.white
        
        self.collectionView.alwaysBounceVertical = true
        
        self.collectionView.register(ChatLogMessageCell.self, forCellWithReuseIdentifier: self.cellId)
        
        self.view.addSubview(messageInputContainerView)
        
        self.view.addConstraintsWithFormat(format: "H:|[v0]|", views: self.messageInputContainerView)
        self.view.addConstraintsWithFormat(format: "V:[v0(58)]", views: self.messageInputContainerView)
        
        self.bottomConstraint = NSLayoutConstraint(item: self.messageInputContainerView, attribute: .bottom, relatedBy: .equal, toItem: self.view, attribute: .bottom, multiplier: 1, constant: 0)
        
        self.view.addConstraint(bottomConstraint!)
        
        self.setupInputComponents()
        
        NotificationCenter.default.addObserver(self, selector: #selector(self.handleKeyboardNotification), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.handleKeyboardNotification), name: UIResponder.keyboardWillHideNotification, object: nil)
        
        self.view.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(self.dismissKeyboard)))
        
        let button1 = UIBarButtonItem(image: nil, style: .plain, target: self, action: #selector(self.handleReportPressed))
        button1.title = "Report"
        self.navigationItem.setRightBarButton(button1, animated: true)
    }
    
    @objc func handleReportPressed() {
        guard let unwrappedFriendProfile = self.friendProfile else {
            print("No friend profile found, won't display a report pressed alert.")
            return
        }
        let reportAlert = UIAlertController(title: "User reported.", message: "\(unwrappedFriendProfile.firstName) was reported.", preferredStyle: .alert)
        reportAlert.addAction(UIAlertAction(title: "OK", style: .default))
        self.present(reportAlert, animated: true, completion: nil)
        
    }
    
    @objc func handleSend() {
        guard let unwrappedInputText = self.inputTextField.text else {
            print("Cannot store nil text as a new message in this conversation")
            return
        }
        if unwrappedInputText.count == 0 {
            let sendMessageFailedAlert = UIAlertController(title: "Send failed.", message: "You can't send empty messages to your friend.", preferredStyle: .alert)
            sendMessageFailedAlert.addAction(UIAlertAction(title: "OK", style: .default))
            self.present(sendMessageFailedAlert, animated: true, completion: nil)
        }
        
        guard let unwrappedConversationsRef = self.conversationsRef,
              let unwrappedActiveUser = self.activeUser,
              let unwrappedFriendProfile = self.friendProfile else {
            print("Couldn't find valid firebase reference for conversations, will not store new message.")
            return
        }
        
        let currentStringDate = DateUtils.convertDateToString(date: Date())
        
        if self.conversation == nil && self.conversationOfFriend == nil {
            let activeUserFriend = Friend(uid: unwrappedActiveUser.uid, firstName: unwrappedActiveUser.firstName, lastName: unwrappedActiveUser.lastName)
            let matchedUserFriend = Friend(uid: unwrappedFriendProfile.uid, firstName: unwrappedFriendProfile.firstName, lastName: unwrappedFriendProfile.lastName)

            let firstMessage = [Message(text: unwrappedInputText, friend: activeUserFriend, date: currentStringDate)]

            let conversationForActiveUser = Conversation(key: activeUserFriend.uid, startDate: currentStringDate, messages: firstMessage, friendProfile: unwrappedFriendProfile)
            let conversationForMatchedUser = Conversation(key: matchedUserFriend.uid, startDate: currentStringDate, messages: firstMessage, friendProfile: unwrappedActiveUser)

            unwrappedConversationsRef.child(unwrappedActiveUser.uid).childByAutoId().setValue(conversationForActiveUser.toAnyObject())
            unwrappedConversationsRef.child(unwrappedFriendProfile.uid).childByAutoId().setValue(conversationForMatchedUser.toAnyObject())

            print("Successfully store new conversations for active and matched users.")
            
            unwrappedConversationsRef.child(unwrappedActiveUser.uid).observeSingleEvent(of: .value, with: { snapshot in
                for child in snapshot.children {
                    if let childSnapshot = child as? DataSnapshot {
                        let conversation = Conversation(snapshot: childSnapshot)
                        guard let unwrappedConversation = conversation else {
                            print("Couldn't construct a valid conversation given this snapshot record: \(childSnapshot)")
                            return
                        }
                        if unwrappedConversation.startDate == conversationForActiveUser.startDate && unwrappedConversation.friendProfile.uid == conversationForActiveUser.friendProfile.uid {
                            self.conversation = unwrappedConversation
                            print(unwrappedConversation)
                            break
                        }
                        
                    }
                }
                
                unwrappedConversationsRef.child(unwrappedFriendProfile.uid).observeSingleEvent(of: .value, with: { snapshot in
                    for child in snapshot.children {
                        if let childSnapshot = child as? DataSnapshot {
                            let conversation = Conversation(snapshot: childSnapshot)
                            guard let unwrappedConversation = conversation else {
                                print("Couldn't construct a valid conversation given this snapshot record: \(childSnapshot)")
                                return
                            }
                            if unwrappedConversation.startDate == conversationForMatchedUser.startDate && unwrappedConversation.friendProfile.uid == conversationForMatchedUser.friendProfile.uid {
                                self.conversationOfFriend = unwrappedConversation
                                print(unwrappedConversation)
                                break
                            }
                            
                        }
                    }
                    let item = self.conversation!.messages.count - 1
                    let insertionIndexPath = IndexPath(item: item, section: 0)
                    self.collectionView.insertItems(at: [insertionIndexPath])
                    self.inputTextField.text = nil
                    self.collectionView.scrollToItem(at: insertionIndexPath, at: .bottom, animated: true)
                })
            })
        } else {
            guard let unwrappedConversation = self.conversation,
                  let unwrappedConversationOfFriend = self.conversationOfFriend else {
                return
            }
            var messagesOfConversation: [Message] = unwrappedConversation.messages
            var messagesOfFriendConversation = unwrappedConversationOfFriend.messages
            let newMessage = Message(text: unwrappedInputText, friend: Friend(uid: unwrappedActiveUser.uid, firstName: unwrappedActiveUser.firstName, lastName: unwrappedActiveUser.lastName), date: DateUtils.convertDateToString(date: Date()))
            messagesOfConversation.append(newMessage)
            messagesOfFriendConversation.append(newMessage)
            
            unwrappedConversationsRef.child(unwrappedActiveUser.uid).child(unwrappedConversation.key).updateChildValues(["messages": messagesOfConversation.map({ $0.toDictionary() })])
            unwrappedConversationsRef.child(unwrappedConversation.friendProfile.uid).child(unwrappedConversationOfFriend.key).updateChildValues(["messages": messagesOfFriendConversation.map({ $0.toDictionary() })])
            print("Successfully updated the messages value in an ongoing conversation between active user and matched user.")
            
            unwrappedConversationsRef.child(unwrappedActiveUser.uid).child(unwrappedConversation.key).observeSingleEvent(of: .value, with: { snapshot in
                guard let unwrappedSnapshot = snapshot as? DataSnapshot else {
                    print("Not a valid snapshot, can't reset conversation in chat log controller after saving new message in it.")
                    return
                }
                let updatedConversation = Conversation(snapshot: unwrappedSnapshot)
                guard let unwrappedUpdatedConversation = updatedConversation else {
                    print("Can't construct an updated conversation given snapshot data, can't update conversation object in chat log controller.")
                    return
                }
                self.conversation = unwrappedUpdatedConversation
                unwrappedConversationsRef.child(unwrappedConversation.friendProfile.uid).child(unwrappedConversationOfFriend.key).observeSingleEvent(of: .value, with: { snapshot in
                    guard let unwrappedFriendSnapshot = snapshot as? DataSnapshot else {
                        print("Not a valid snapshot, can't reset conversation of friend in chat log controller.")
                        return
                    }
                    let updatedConversationOfFriend = Conversation(snapshot: unwrappedFriendSnapshot)
                    guard let unwrappedUpdatedConversationOfFriend = updatedConversationOfFriend else {
                        print("Can't construct an updated conversation of the friend of the active user in the chat log controller.")
                        return
                    }
                    self.conversationOfFriend = unwrappedUpdatedConversationOfFriend
                    let item = self.conversation!.messages.count - 1
                    let insertionIndexPath = IndexPath(item: item, section: 0)
                    self.collectionView.insertItems(at: [insertionIndexPath])
                    self.inputTextField.text = nil
                    self.collectionView.scrollToItem(at: insertionIndexPath, at: .bottom, animated: true)
                })
            })
        }
    }
    
    @objc func handleKeyboardNotification(notification: NSNotification) {
        if let userInfo = notification.userInfo {
            let keyboardFrame = userInfo[UIResponder.keyboardFrameEndUserInfoKey]
            guard let unwrappedKeyboardFrame = keyboardFrame as? CGRect else {
                print("Can't find keyboard frame, so I won't set the bottom contraints of the message input container view.")
                return
            }
            
            let isKeyboardShowing = notification.name == UIResponder.keyboardWillShowNotification
            
            self.bottomConstraint?.constant = isKeyboardShowing ? -unwrappedKeyboardFrame.height : 0
            
            UIView.animate(withDuration: 0, delay: 0, options: UIView.AnimationOptions.curveEaseOut, animations: {
                
                self.view.layoutIfNeeded()
                
            }, completion: { (completed) in
                guard let unwrappedMessages = self.messages else {
                    print("Messages array data is nil, can't auto-update the collection view scrolling when keyboard appears or disappears.")
                    return
                }
                let indexPath = NSIndexPath(item: unwrappedMessages.count - 1, section: 0) as? IndexPath
                guard let unwrappedIndexPath = indexPath else {
                    print("Couldn't unwraped index path from NS index path")
                    return
                }
                self.collectionView.scrollToItem(at: unwrappedIndexPath, at: .bottom, animated: true)
            })
        }
    }
    
    @objc func dismissKeyboard() {
        self.inputTextField.endEditing(true)
    }
    
    private func setupInputComponents() {
        
        let topBorderView = UIView()
        topBorderView.backgroundColor = UIColor(white: 0.5, alpha: 0.5)
        
        self.messageInputContainerView.addSubview(self.inputTextField)
        self.messageInputContainerView.addSubview(self.sendButton)
        self.messageInputContainerView.addSubview(topBorderView)
        self.messageInputContainerView.addConstraintsWithFormat(format: "H:|-18-[v0][v1(60)]-10-|", views: self.inputTextField, self.sendButton)
        self.messageInputContainerView.addConstraintsWithFormat(format: "V:|[v0]-8-|", views: self.inputTextField)
        self.messageInputContainerView.addConstraintsWithFormat(format: "V:|[v0]-8-|", views: self.sendButton)
        self.messageInputContainerView.addConstraintsWithFormat(format: "H:|[v0]|", views: topBorderView)
        self.messageInputContainerView.addConstraintsWithFormat(format: "V:|[v0(0.5)]", views: topBorderView)
    }
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.messages?.count ?? 0
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = self.collectionView.dequeueReusableCell(withReuseIdentifier: self.cellId, for: indexPath) as! ChatLogMessageCell
        
        guard let unwrappedMessages = self.messages,
              let unwrappedActiveUser = self.activeUser else {
            print("Messages is nil or there is no active user for this VC, cannot set custom CG size for message cell.")
            return UICollectionViewCell()
        }
        
        let messageText = unwrappedMessages[indexPath.item].text
        let size = CGSize(width: 250, height: 1000)
        let options = NSStringDrawingOptions.usesFontLeading.union(.usesLineFragmentOrigin)
        let estimatedFrame = NSString(string: messageText).boundingRect(with: size, options: options, attributes: [NSAttributedString.Key.font: UIFont.systemFont(ofSize: 18)], context: nil)
        
        cell.messageTextView.text = unwrappedMessages[indexPath.item].text
        let horizontalPadding: CGFloat = 8.0
        
        let message = unwrappedMessages[indexPath.item]
        
        if !message.isSender(uid: unwrappedActiveUser.uid) {
            cell.messageTextView.frame = CGRect(x: 20 + horizontalPadding, y: 0, width: estimatedFrame.width + 16, height: estimatedFrame.height + 15)
            cell.textBubbleView.frame = CGRect(x: 20, y: 0, width: estimatedFrame.width + 16 + horizontalPadding, height: estimatedFrame.height + 15)
            cell.textBubbleView.backgroundColor = UIColor(white: 0.95, alpha: 1)
            cell.messageTextView.textColor = UIColor.black
        } else {
            cell.messageTextView.frame = CGRect(x: view.frame.width - estimatedFrame.width - 16 - 16, y: 0, width: estimatedFrame.width + 16, height: estimatedFrame.height + 15)
            cell.textBubbleView.frame = CGRect(x: view.frame.width - estimatedFrame.width - 16 - horizontalPadding - 16, y: 0, width: estimatedFrame.width + 16 + horizontalPadding, height: estimatedFrame.height + 15)
            cell.textBubbleView.backgroundColor = UIColor(red: 0, green: 137/255, blue: 249/255, alpha: 1)
            cell.messageTextView.textColor = UIColor.white
        }
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        
        guard let unwrappedMessages = self.messages else {
            print("Messages is nil, cannot set custom CG size for message cell.")
            return CGSize(width: 250, height: 100)
        }
        
        let messageText = unwrappedMessages[indexPath.item].text
        let size = CGSize(width: 250, height: 1000)
        let options = NSStringDrawingOptions.usesFontLeading.union(.usesLineFragmentOrigin)
        let estimatedFrame = NSString(string: messageText).boundingRect(with: size, options: options, attributes: [NSAttributedString.Key.font: UIFont.systemFont(ofSize: 18)], context: nil)
        
        return CGSize(width: view.frame.width, height: estimatedFrame.height + 15)
    }
    
}

class ChatLogMessageCell: BaseCell {
    
    let messageTextView: UITextView = {
        let textView = UITextView()
        textView.font = UIFont.systemFont(ofSize: 16)
        textView.text = "Sample message"
        textView.backgroundColor = UIColor.clear
        return textView
    }()
    
    let textBubbleView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor(white: 0.95, alpha: 1)
        view.layer.cornerRadius = 15
        view.layer.masksToBounds = true
        return view
    }()
    
    let fillerView: UIView = {
        let view = UIView()
        view.layer.cornerRadius = 15
        view.layer.masksToBounds = true
        view.backgroundColor = UIColor.white
        return view
    }()
    
    override func setupViews() {
        super.setupViews()
        
        addSubview(textBubbleView)
        addSubview(messageTextView)

    }
}
