//
//  LoginViewController.swift
//  Pocket Accountant
//
//  Created by Alexandr on 13.01.17.
//  Copyright © 2017 Alexandr. All rights reserved.
//

import UIKit

class LoginViewController: UIViewController {

    @IBOutlet var loginTextField: UITextField!
    @IBOutlet var scrollView: UIScrollView!
    @IBOutlet var loginTextfFieldBottomConstraint: NSLayoutConstraint!
    var scroll = false
    let coreData = CoreDataManager.shared
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        get {
            return .lightContent
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        loginTextField.delegate = self
        
        NotificationCenter.default.addObserver(self, selector: #selector(LoginViewController.keyboardWillShow(notification:)), name:
            NSNotification.Name.UIKeyboardWillShow, object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(LoginViewController.keyboardWillHide(notification:)), name:
            NSNotification.Name.UIKeyboardWillHide, object: nil)
    }
    
    func keyboardWillShow(notification: NSNotification) {
        if let keyboardSize = (notification.userInfo?[UIKeyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue {
            if scroll {
                scrollView.setContentOffset(CGPoint(x: 0, y: keyboardSize.size.height - loginTextfFieldBottomConstraint.constant + 15), animated: true)
            }
        } else {
            debugPrint("We're showing the keyboard and either the keyboard size or window is nil: panic widely.")
        }
    }
    
    func keyboardWillHide(notification: NSNotification) {
        if scroll {
            scrollView.setContentOffset(CGPoint(x: 0, y: 0), animated: true)
            
            scroll = false
        }
    }
    
    func saveToUserDefaults(login: String) {
        UserDefaults.standard.set(login, forKey: "user")
        
        if coreData.fetch(user: login) == nil {
            coreData.save(user: login)
        }
    }
    
    //MARK: - Navigation
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "segueToChat" {
            let nvc = segue.destination as! UINavigationController
            let vc = nvc.viewControllers.first as! ChatViewController
            
            let login = loginTextField.text
            
            vc.senderId = login
            vc.senderDisplayName = login
            
            saveToUserDefaults(login: login!)
        }
    }
    
}

extension LoginViewController: UITextFieldDelegate {
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField == loginTextField {
            textField.resignFirstResponder()
            performSegue(withIdentifier: "segueToChat", sender: self)
            
            return false
        }
        return true
    }
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        if textField == loginTextField {
            if textField.frame.origin.y > UIScreen.main.bounds.size.height/2 {
                scroll = true
            }
        }
    }
    
}
