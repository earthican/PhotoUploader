//
//  PhotoUploaderViewController.swift
//  PhotoUploader
//
//  Created by Justin Cano on 4/22/15.
//  Copyright (c) 2015 bumrush. All rights reserved.
//

import UIKit
import MobileCoreServices
import AssetsLibrary

class PhotoUploaderViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {

    @IBAction func choosePhoto(sender: UIButton) {
        if UIImagePickerController.isSourceTypeAvailable(.PhotoLibrary) {
            let picker = UIImagePickerController()
            picker.sourceType = .PhotoLibrary
            if let availableTypes = UIImagePickerController.availableMediaTypesForSourceType(.PhotoLibrary) {
                picker.mediaTypes = [kUTTypeImage]
                picker.delegate = self
                //picker.allowsEditing = true
                presentViewController(picker, animated: true, completion: nil)
            }
        }
    }
    
    private func updateUI() {
        makeRoomForImage()
    }
    
    // MARK: - Image
    
    var imageView = UIImageView()
    @IBOutlet weak var imageViewContainer: UIView! {
        didSet {
            imageViewContainer.addSubview(imageView)
        }
    }
    
    // MARK: - Delegate Methods
    
    func imagePickerController(picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [NSObject : AnyObject] ) {
        var image = info[UIImagePickerControllerEditedImage] as? UIImage
        if image == nil {
            image = info[UIImagePickerControllerOriginalImage] as? UIImage
        }
        
        //process image
        imageView.image = image
        makeRoomForImage()
        
        //save image to app's temp folder
        let path = NSTemporaryDirectory().stringByAppendingPathComponent("upload-image.tmp")
        let imageData = UIImagePNGRepresentation(image)
        imageData.writeToFile(path, atomically: true)
        
//        let imageURL = NSURL(string: path)
        let imageURL = NSURL(fileURLWithPath: path)
        let uploadRequest = AWSS3TransferManagerUploadRequest()
        uploadRequest.bucket = S3BucketName
        uploadRequest.key = "test-file"
        uploadRequest.body = imageURL
        
        let transferManager = AWSS3TransferManager.defaultS3TransferManager()
        transferManager.upload(uploadRequest).continueWithExecutor(BFExecutor.mainThreadExecutor(), withBlock: { (task) -> AnyObject! in
            if task.error != nil {
                println("\(task.error)")
                println("Error uploading: \(imageURL)")
            } else {
                println("Upload completed!")
            }
            return nil
        })

        dismissViewControllerAnimated(true, completion: nil)
    }
    
    func imagePickerControllerDidCancel(picker: UIImagePickerController) {
        dismissViewControllerAnimated(true, completion: nil)
    }
    
    // MARK: - Helper Methods
    
    func makeRoomForImage() {
        var extraHeight:CGFloat = 0
        if imageView.image?.aspectRatio > 0 {
            if let width = imageView.superview?.frame.size.width {
                let height = width / imageView.image!.aspectRatio
                extraHeight = height - imageView.frame.height
                imageView.frame = CGRect(x: 0, y: 0, width: width, height: height)
            }
        } else {
            extraHeight = -imageView.frame.height
            imageView.frame = CGRectZero
        }
        preferredContentSize = CGSize(width: preferredContentSize.width, height: preferredContentSize.height + extraHeight)
    }
}

extension UIImage {
    var aspectRatio:CGFloat {
        return size.height != 0 ? size.width / size.height : 0
    }
}