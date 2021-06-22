//
//  ChatViewController.swift
//  Flash Chat iOS13
//
//  Created by Angela Yu on 21/10/2019.
//  Copyright © 2019 Angela Yu. All rights reserved.
//

import UIKit
import Firebase

class ChatViewController: UIViewController {
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var messageTextfield: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.dataSource = self
        title = "⚡️FlashChat"
        navigationItem.hidesBackButton = true
        tableView.register(UINib(nibName: K.cellNibName, bundle: nil), forCellReuseIdentifier: K.cellIdentifier)
        loadMessages()
    }
    
    let db = Firestore.firestore()
    
    var messages: [Message] = []
    
    
    @IBAction func sendPressed(_ sender: UIButton) {
        //        let messageBody = messageTextfield.text
        //        let messageSender =  Auth.auth().currentUser?.email
        guard let messageBody = messageTextfield.text, let messageSender = Auth.auth().currentUser?.email else {
            return
        }
        if !(messageBody.isEmpty) {
            db.collection(K.FStore.collectionName).addDocument(data: [
                K.FStore.senderField: messageSender,
                K.FStore.bodyField: messageBody,
                K.FStore.dateField: Date().timeIntervalSince1970
            ]) { (error) in
                if error != nil {
                    print("There was an error")
                } else {
                    print("Successfully added to the database")
                    DispatchQueue.main.async {
                        self.messageTextfield.text = "" 
                    }
                }
            }
        }
    }
    
    func loadMessages() {
        
        db.collection(K.FStore.collectionName)
            .order(by: K.FStore.dateField)
            .addSnapshotListener() { (querySnapshot, err) in
                //Making the message not to be repetittive
                self.messages = []
                if err != nil {
                    print("There was an error fetching documents")
                } else {
                    guard let snapShotDocument = querySnapshot?.documents else {return}
                    for document in snapShotDocument {
                        print(document.data())
                        guard let senderMessage = document.data()[K.FStore.senderField] as? String else {return}
                        guard let senderBody = document.data()[K.FStore.bodyField] as? String else {return}
                        let newMessage = Message(sender: senderMessage, body: senderBody)
                        
                        self.messages.append(newMessage)
                        
                        DispatchQueue.main.async {
                            self.tableView.reloadData()
                            let scrollIndex = IndexPath(row: self.messages.count - 1, section: 0)
                            self.tableView.scrollToRow(at: scrollIndex, at: .top, animated: false)
                        }
                    }
                    
                }
            }
    }
    
    @IBAction func logOutPressed(_ sender: UIBarButtonItem) {
        let firebaseAuth = Auth.auth()
        do {
            try firebaseAuth.signOut()
            navigationController?.popToRootViewController(animated: true)
        } catch let signOutError as NSError {
            print ("Error signing out: %@", signOutError)
        }
        
    }
}

extension ChatViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return messages.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let message = messages[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: K.cellIdentifier, for: indexPath) as! MessageCell
        //        cell.textLabel?.text = messages[indexPath.row].sender
        cell.label.text = message.body
        
        if message.sender == Auth.auth().currentUser?.email {
            cell.leftImageView.isHidden = true
            cell.rightImageView.isHidden = false
            cell.MessageBubble.backgroundColor = UIColor(named: K.BrandColors.lightPurple)
            cell.label.textColor = UIColor(named: K.BrandColors.purple)
        } else {
            cell.leftImageView.isHidden = false
            cell.rightImageView.isHidden = true
            cell.MessageBubble.backgroundColor = UIColor(named: K.BrandColors.purple)
            cell.label.textColor = UIColor(named: K.BrandColors.lightPurple)
        }
        
        return cell
    }
    
    
}
