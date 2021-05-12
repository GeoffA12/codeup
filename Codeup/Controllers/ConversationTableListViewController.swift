//
//  ConversationTableListViewController.swift
//  Codeup
//
//  Created by Geoff Arroyo on 4/25/21.
//

import UIKit
import Firebase

class ConversationTableListViewController: UICollectionViewController, UICollectionViewDelegateFlowLayout {
    
    var conversations: [Conversation]?
    
    var ref: DatabaseReference?
    
    var activeUser: UserProfile?
    
    private let cellId = "cellId"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.collectionView.backgroundColor = UIColor.white
        
        self.collectionView.alwaysBounceVertical = true
        
        self.collectionView.register(ConversationCell.self, forCellWithReuseIdentifier: self.cellId)
        
        var userProfilePath : String?
        var conversationsPath: String?
        
        do {
            userProfilePath = try DatabasePathUtils.checkDatabasePathExists(path: DatabaseCollections[Collections.UserProfile])
            conversationsPath = try DatabasePathUtils.checkDatabasePathExists(path: DatabaseCollections[Collections.Conversations])
        } catch (let error) {
            print(error)
        }
        
        guard let validUserProfilePath = userProfilePath,
              let userDefaultsUserProfile = UserDefaults.standard.object(forKey: validUserProfilePath),
              let validUserDefaultsUserProfile = userDefaultsUserProfile as? [String:Any],
              let activeUserProfile = UserProfile(dictionary: validUserDefaultsUserProfile) else {
            print("Couldn't fetch user profile from user defaults, backing out of view did load now.")
            return
        }
        
        guard let validConversationsPath = conversationsPath else {
            print("Couldn't unwrap the conversations firebase DB path, backing out of view did load now.")
            return
        }
        
        self.activeUser = activeUserProfile
        
        self.ref = Database.database().reference(withPath: validConversationsPath)
        
        self.ref?.child(activeUserProfile.uid).observe(.value, with: { snapshot in
            var newConversations: [Conversation] = []
            for child in snapshot.children {
                if let snapshot = child as? DataSnapshot,
                   let conversation = Conversation(snapshot: snapshot) {
                    newConversations.append(conversation)
                }
            }
            // We want the most recent conversations to be at the top of the conversation list.
            newConversations.sort(by: { $0.startDate.compare($1.startDate) == .orderedDescending })
            // let sortedConversations = newConversations.sorted(by: { $0.startDate > $1.startDate})
            self.conversations = newConversations
            self.collectionView.reloadData()
        })
    }
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.conversations?.count ?? 0
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = self.collectionView.dequeueReusableCell(withReuseIdentifier: self.cellId, for: indexPath) as! ConversationCell
        
        if let conversation = self.conversations?[indexPath.item] {
            cell.conversation = conversation
        }
        
        return cell
    }
    
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let layout = UICollectionViewFlowLayout()
        
        let controller = ChatLogViewController(collectionViewLayout: layout)
        
        guard let unwrappedConversations = self.conversations else {
            print("Can't transition to the chat log because conversations is nil.")
            return
        }
        
        let targetConversation = unwrappedConversations[indexPath.item]
        
        let friendUidOfTargetConversation = targetConversation.friendProfile.uid
        
        var matchingConversationOfFriend: Conversation?
        
        let dispatchGroup = DispatchGroup()
        
        dispatchGroup.enter()
        
        self.ref?.child(friendUidOfTargetConversation).observeSingleEvent(of: .value, with: { snapshot in
            
            for child in snapshot.children {
                if let snapshot = child as? DataSnapshot,
                   let conversation = Conversation(snapshot: snapshot) {
                    if conversation.startDate == targetConversation.startDate {
                        matchingConversationOfFriend = conversation
                        break
                    }
                }
            }
            controller.conversation = unwrappedConversations[indexPath.item]
            controller.friendProfile = unwrappedConversations[indexPath.item].friendProfile
            controller.activeUser = self.activeUser
            controller.conversationsRef = self.ref
            controller.conversationOfFriend = matchingConversationOfFriend
            dispatchGroup.leave()
        })
        
        dispatchGroup.notify(queue: .main) {
            self.navigationController?.pushViewController(controller, animated: true)
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: view.frame.width, height: 100)
    }
}

class ConversationCell: BaseCell {
    
    override var isHighlighted: Bool {
        didSet {
            backgroundColor = isHighlighted ? UIColor(red: 0, green: 134/255, blue: 249/255, alpha: 1) : UIColor.white
            nameLabel.textColor = isHighlighted ? UIColor.white : UIColor.black
            messageLabel.textColor = isHighlighted ? UIColor.white : UIColor.black
            timeLabel.textColor = isHighlighted ? UIColor.white : UIColor.black
        }
    }
    
    var conversation: Conversation? {
        didSet {
            guard let unwrappedConversation = self.conversation else {
                print("Not a valid conversation constructor, cannot construct the conversation cell.")
                return
            }
            let latestMessage = unwrappedConversation.getLatestMessage()
            guard let unwrappedLatestMessage = latestMessage else {
                print("No latest message found for this conversation, backing out now.")
                nameLabel.text = nil
                messageLabel.text = nil
                timeLabel.text = nil
                return
            }
            let potentialDate = DateUtils.convertStringToDate(isoString: unwrappedConversation.startDate)

            guard let unwrappedDate = potentialDate else {
                return
            }
            
            let df = DateFormatter()
            df.dateFormat = "h:mm a"
            
            let elapsedTimeInSeconds = NSDate().timeIntervalSince(unwrappedDate)
            
            let secondsInDay: TimeInterval = 60 * 60 * 20
            
            let secondsInWeek: TimeInterval = secondsInDay * 7
            
            if elapsedTimeInSeconds > secondsInWeek {
                df.dateFormat = "MM/dd/yy"
            } else if elapsedTimeInSeconds > secondsInDay {
                df.dateFormat = "EEE"
            }
            
            nameLabel.text = unwrappedConversation.friendProfile.firstName + " " + unwrappedConversation.friendProfile.lastName
            messageLabel.text = unwrappedLatestMessage.text
            timeLabel.text = df.string(from: unwrappedDate)
        }
    }
    
    let dividerLineView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor(white: 0.5, alpha: 0.5)
        return view
    }()
    
    let nameLabel: UILabel = {
        let label = UILabel()
        label.text = "Friend name"
        return label
    }()
    
    let messageLabel: UILabel = {
        let label = UILabel()
        label.text = "Your friend's message and something else"
        label.textColor = UIColor.darkGray
        return label
    }()
    
    let timeLabel: UILabel = {
        let label = UILabel()
        label.text = "12:05 PM"
        label.textAlignment = .right
        label.font = UIFont.systemFont(ofSize: 16)
        return label
    }()
    
    
    override func setupViews() {
        addSubview(dividerLineView)
        
        setupContainerView()
        
        dividerLineView.translatesAutoresizingMaskIntoConstraints = false
        
        addConstraintsWithFormat(format: "H:|[v0]|", views: dividerLineView)
        addConstraintsWithFormat(format: "V:[v0(1)]|", views: dividerLineView)
        
    }
    
    private func setupContainerView() {
        let containerView = UIView()
        
        addSubview(containerView)
        
        addConstraintsWithFormat(format: "H:|[v0(325)]|", views: containerView)
        
        addConstraintsWithFormat(format: "V:[v0(85)]", views: containerView)
        
        addConstraint(NSLayoutConstraint(item: containerView, attribute: .centerY, relatedBy: .equal, toItem: self, attribute: .centerY, multiplier: 1, constant: 0))
        
        containerView.addSubview(nameLabel)
        containerView.addSubview(messageLabel)
        containerView.addSubview(timeLabel)
        
         containerView.addConstraintsWithFormat(format: "H:|-10-[v0][v1(80)]-10-|", views: nameLabel, timeLabel)

        containerView.addConstraintsWithFormat(format: "V:|[v0][v1(24)]-2-|", views: nameLabel, messageLabel)

        containerView.addConstraintsWithFormat(format: "H:|-10-[v0]-10-|", views: messageLabel)

        containerView.addConstraintsWithFormat(format: "V:|-12-[v0(20)]", views: timeLabel)
    }
}

class BaseCell: UICollectionViewCell {
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented.")
    }
    
    func setupViews() {
    }
}

extension UIView {
    func addConstraintsWithFormat(format: String, views: UIView...) {
        var viewsDictionary = [String: UIView]()
        
        for (index, view) in views.enumerated() {
            let key = "v\(index)"
            viewsDictionary[key] = view
            view.translatesAutoresizingMaskIntoConstraints = false
        }
        
        addConstraints(NSLayoutConstraint.constraints(withVisualFormat: format, options: NSLayoutConstraint.FormatOptions(), metrics: nil, views: viewsDictionary))
    }
}
