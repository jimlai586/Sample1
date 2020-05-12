//
//  ViewController.swift
//  SwTest1
//
//  Created by JimLai on 2020/4/11.
//  Copyright © 2020 stargate. All rights reserved.
//

import UIKit

protocol ReBio: class {
    var editable: Bool {get set}
    var avatar: UIImageView! {get set}
    var bio: UITextView! {get set}
    var words: UILabel! {get set}
    var wordLimit: Int {get}
    var avatarChanged: Bool {get}
    var bioChanged: Bool {get}
    var initialAvatar: UIImage? {get set}
    var initialBio: String {get set}
    var resAvatar: Json {get set}
    var resBio: Json {get set}
    func updateAvatar(_ img: UIImage?)
    func updateBio(_ text: String)
    func toggleEditable(_ b: Bool?)
    func restore()
    func action(_ lvc: LoadScreenVC, _ img: UIImage?, _ bio: String?)
    
}

extension ReBio {
    var wordLimit: Int {
        return 200
    }
    
    var bioChanged: Bool {
        return initialBio != bio.text
    }
    var avatarChanged: Bool {
        guard let oldPng = initialAvatar?.jpegData(compressionQuality: 0.0), let newPng = avatar.image?.jpegData(compressionQuality: 0.0) else {return false}
        return !(oldPng == newPng)
    }
    
    func updateAvatar(_ img: UIImage?) {
        avatar.image = img
    }
    
    func updateBio(_ text: String) {
        bio.text = text
        updateWords(text)
    }
    
    func updateWords(_ text: String) {
        words.text = "\(text.count)/\(wordLimit)"
    }
    
    func toggleEditable(_ b: Bool? = nil) {
        if let b = b {
            editable = b
        } else {
            editable = !editable
        }
    }
    func restore() {
        updateAvatar(initialAvatar)
        updateBio(initialBio)
        toggleEditable(false)
    }
    
    func action(_ lvc: LoadScreenVC, _ img: UIImage?, _ bio: String?) {
        lvc.dismiss()
        if let img = img {
            initialAvatar = img
        }
        if let bio = bio {
            initialBio = bio
        }
        toggleEditable(false)
    }
}


class ViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate, UITextViewDelegate, ReBio {
    @IBOutlet var backBtn: UIButton!
    @IBOutlet var save: UIButton!
    var editable = false {
        didSet {
            if editable {
                bio.isEditable = true
                backBtn.isHidden = false
                save.isHidden = false
                avatar.isUserInteractionEnabled = true
                edit.isHidden = true
            } else {
                bio.isEditable = false
                backBtn.isHidden = true
                save.isHidden = true
                avatar.isUserInteractionEnabled = false
                edit.isHidden = false
            }
        }
    }
    
    var backAlert: UIAlertController {
        let avc = UIAlertController(title: "Alert!", message: "Are you sure to cancel?\n Changes will be lost", preferredStyle: .alert)
        let ok = UIAlertAction(title: "Confirm", style: .destructive) { (_) in
            self.restore()
        }
        let cancel = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        avc.addAction(ok)
        avc.addAction(cancel)
        return avc
    }
    
    @IBOutlet var words: UILabel!
    @IBOutlet var edit: UIButton!
    @IBOutlet var bio: UITextView!
    @IBOutlet var avatar: UIImageView!
    let imgPicker = UIImagePickerController()
    var initialBio = ""
    var initialAvatar: UIImage?
    var resAvatar = Json("https://api.mock.com/me/avatar")
    var resBio = Json("https://api.mock.com/me")
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        imgPicker.delegate = self
        imgPicker.sourceType = .photoLibrary
        
        bio.delegate = self
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(onTap(_:)))
        avatar.addGestureRecognizer(tap)
        
        let endEditTap = UITapGestureRecognizer(target: self, action: #selector(endEditing(_:)))
        
        view.addGestureRecognizer(endEditTap)
        
        edit.addTarget(self, action: #selector(onEdit(_:)), for: .touchUpInside)
        
        backBtn.addTarget(self, action: #selector(onBack(_:)), for: .touchUpInside)
        
        save.addTarget(self, action: #selector(onSave(_:)), for: .touchUpInside)
        
        toggleEditable(false)
        
        updateWords(bio.text)
        
        initialBio = bio.text
        
        initialAvatar = avatar.image
        
    }
    @objc func onSave(_ sender: Any) {
        if avatarChanged {
            let loadVC = sb() as LoadScreenVC
            present(loadVC, animated: true, completion: nil)
            let avImg = avatar.image
            resAvatar.post(avImg).onSuccess { _ in
                self.action(loadVC, avImg, nil)
            }
        }
        if bioChanged {
            let loadVC = sb() as LoadScreenVC
            present(loadVC, animated: true, completion: nil)
            let bt = bio.text ?? ""
            resBio.patch(bt).onSuccess { _ in
                self.action(loadVC, nil, bt)
            }
        }
    }
    
    @objc func onBack(_ sender: Any) {
        guard avatarChanged || bioChanged else {
            restore()
            return
        }
        present(backAlert, animated: true, completion: nil)
    }
    
    @objc func onEdit(_ sender: UIButton) {
        toggleEditable()
    }
    
    @objc func onTap(_ sender: UIImageView) {
        present(imgPicker, animated: true, completion: nil)
    }
    @objc func endEditing(_ sender: Any) {
        view.endEditing(true)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        imgPicker.dismiss(animated: true)
        
        print(info)
        guard let image = info[.originalImage] as? UIImage else {
            print("No image found")
            return
        }
        updateAvatar(image)
    }
    
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        guard textView.text.count + text.count <= wordLimit else {
            return false
        }
        return true
    }
    
    func textViewDidEndEditing(_ textView: UITextView) {
        updateWords(textView.text)
    }
    

}

