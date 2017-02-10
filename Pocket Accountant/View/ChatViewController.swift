//
//  ChatViewController.swift
//  Pocket Accountant
//
//  Created by Alexandr on 13.01.17.
//  Copyright © 2017 Alexandr. All rights reserved.
//

import UIKit
import JSQMessagesViewController

class ChatViewController: JSQMessagesViewController {
    
    var messages = [JSQMessage]()
    let botId = "bot"
    let botDisplayName = "Accountant"
    let bot = Bot.shared
    let coreData = CoreDataManager.shared
    var user: User!
    var start = true
    
    lazy var outgoingBubbleImageView: JSQMessagesBubbleImage = self.setupOutgoingBubble()
    lazy var incomingBubbleImageView: JSQMessagesBubbleImage = self.setupIncomingBubble()
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        get {
            return .lightContent
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let rightButton = UIBarButtonItem(barButtonSystemItem: .edit, target: self, action: #selector(ChatViewController.signOutAlert(sender:)))
        rightButton.tintColor = UIColor.white
        navigationItem.rightBarButtonItem = rightButton
        
        loadUserInfo()
        
        // Remove attach button
        inputToolbar.contentView.leftBarButtonItem = nil
        
        // No avatars
        collectionView!.collectionViewLayout.incomingAvatarViewSize = CGSize.zero
        collectionView!.collectionViewLayout.outgoingAvatarViewSize = CGSize.zero
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if start {
            loadEarlierMessages()
        }

    }
    
    private func setupOutgoingBubble() -> JSQMessagesBubbleImage {
        let bubbleImageFactory = JSQMessagesBubbleImageFactory()
        return bubbleImageFactory!.outgoingMessagesBubbleImage(with: UIColor.jsq_messageBubbleBlue())
    }
    
    private func setupIncomingBubble() -> JSQMessagesBubbleImage {
        let bubbleImageFactory = JSQMessagesBubbleImageFactory()
        return bubbleImageFactory!.incomingMessagesBubbleImage(with: UIColor.jsq_messageBubbleLightGray())
    }
    
    func addMessage(withId id: String, name: String, text: String) {
        if let message = JSQMessage(senderId: id, displayName: name, text: text) {
            messages.append(message)
            coreData.save(msg: text, id: id, user: user)
        }
    }
    
    func responseRobot(text: String) {
        let msgtext = bot.message(text: text)
        addMessage(withId: botId, name: botDisplayName, text: msgtext)
        DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(300)) {
            self.finishReceivingMessage()
        }
    }
    
    func loadUserInfo() {
        let defaults = UserDefaults.standard
        
        guard let user = defaults.string(forKey: "user") else {
            return
        }
        
        senderId = user
        senderDisplayName = user
        self.user = coreData.fetch(user: user)
        self.bot.user = self.user
    }
    
    func loadEarlierMessages() {
        let messages = coreData.fetch(amount: 5, from: user)
        
        guard messages.count > 0 else {
            if start {
                firstGreetings()
                
                self.start = false
            }
            
            return
        }
        
        insertAtStart(messages: messages)
        
        var indexPaths = [IndexPath]()
        for index in 0...messages.count-1 {
            indexPaths.append(IndexPath(row: index, section: 0))
        }
        
        DispatchQueue.main.async {
            if !self.start {
                CATransaction.begin()
                CATransaction.setDisableActions(true)
            }
            
            let bottomOffset = self.collectionView.contentSize.height - self.collectionView.contentOffset.y
            
            self.collectionView.performBatchUpdates({
                self.collectionView.insertItems(at: indexPaths)
            }, completion: { (finished) in
                if !self.start {
                    self.collectionView.contentOffset = CGPoint(x: 0, y: self.collectionView.contentSize.height - bottomOffset)
                    CATransaction.commit()
                } else {
                    self.start = false
                }
            })
        }
        
    }
    
    func insertAtStart(messages: [Message]) {
        for message in messages {
            let msg = JSQMessage(senderId: message.senderId, displayName: message.displayName, text: message.message)
            self.messages.insert(msg!, at: 0)
        }
    }
    
    func firstGreetings() {
        addMessage(withId: botId, name: botDisplayName, text: "Yo!")
        addMessage(withId: botId, name: botDisplayName, text: "Hello, \(senderDisplayName!)! I am your assistant. I am here to help you with your finances")
        coreData.fetchedItems = 2
        
        finishReceivingMessage()
    }
    
    func signOut() {
        UserDefaults.standard.removeObject(forKey: "user")
        coreData.fetchedItems = 0
    }
    
    func signOutAlert(sender: AnyObject?) {
        let alert = UIAlertController(title: "Sign out", message: "Are you sure ?", preferredStyle: .actionSheet)
        alert.addAction(UIAlertAction(title: "Yes", style: .destructive, handler: {
            (action) in
            DispatchQueue.main.async {
                self.signOut()
                self.performSegue(withIdentifier: "segueToLogin", sender: self)
            }
        }))
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        present(alert, animated: true, completion: nil)
    }
    
    //MARK: - Navigation
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "segueToLogin" {
            signOut()
        }
    }

}

extension ChatViewController {
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return messages.count
    }
    
    override func collectionView(_ collectionView: JSQMessagesCollectionView!, messageBubbleImageDataForItemAt indexPath: IndexPath!) -> JSQMessageBubbleImageDataSource! {
        let message = messages[indexPath.row]
        if message.senderId == senderId {
            return outgoingBubbleImageView
        }
        else {
            return incomingBubbleImageView
        }
    }
    
    override func collectionView(_ collectionView: JSQMessagesCollectionView!, avatarImageDataForItemAt indexPath: IndexPath!) -> JSQMessageAvatarImageDataSource! {
        return nil
    }
    
    override func collectionView(_ collectionView: JSQMessagesCollectionView!, messageDataForItemAt indexPath: IndexPath!) -> JSQMessageData! {
        return messages[indexPath.row]
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell{
        let cell = super.collectionView(collectionView, cellForItemAt: indexPath) as! JSQMessagesCollectionViewCell
        
        let message = messages[indexPath.item]
        
        if message.senderId == senderId {
            cell.textView!.textColor = UIColor.white
        } else {
            cell.textView!.textColor = UIColor.black
        }
        
        return cell
    }
    
    override func didPressSend(_ button: UIButton!, withMessageText text: String!, senderId: String!, senderDisplayName: String!, date: Date!) {
        addMessage(withId: senderId, name: senderDisplayName, text: text)
        JSQSystemSoundPlayer.jsq_playMessageSentSound()
        finishSendingMessage()
        responseRobot(text: text)
    }
    
    override func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        for cell in collectionView.visibleCells  as [UICollectionViewCell]    {
            let indexPath = collectionView.indexPath(for: cell as UICollectionViewCell)
            let row = indexPath?.row
            if row == 0 {
                loadEarlierMessages()
            }
        }
    }
    
}
