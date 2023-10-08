//
//  CNContactVC.swift
//  OneDisc
//
//  Created by Justin Lawrence on 9/27/23.
//

import Foundation
import ContactsUI
import SwiftUI

struct CNContactViewControllerRepresentable: UIViewControllerRepresentable {
typealias UIViewControllerType = CNContactViewController
    var contact: Binding<CNContact>

    func makeCoordinator() -> CNContactViewControllerRepresentable.Coordinator {
        Coordinator(self)
    }

    func makeUIViewController(context: UIViewControllerRepresentableContext<CNContactViewControllerRepresentable>) -> CNContactViewControllerRepresentable.UIViewControllerType {
        let controller = CNContactViewController(forNewContact: contact.wrappedValue)
        controller.delegate = context.coordinator
        return controller
    }

    func updateUIViewController(_ uiViewController: CNContactViewControllerRepresentable.UIViewControllerType, context: UIViewControllerRepresentableContext<CNContactViewControllerRepresentable>) {
        //
    }

    // Nested coordinator class, the prefered way stated in SwiftUI documentation.
    class Coordinator: NSObject, CNContactViewControllerDelegate {
        var parent: CNContactViewControllerRepresentable

        init(_ contactDetail: CNContactViewControllerRepresentable) {
            self.parent = contactDetail
        }

        func contactViewController(_ viewController: CNContactViewController, didCompleteWith contact: CNContact?) {
            parent.contact.wrappedValue = contact ?? parent.contact.wrappedValue
        }

        func contactViewController(_ viewController: CNContactViewController, shouldPerformDefaultActionFor property: CNContactProperty) -> Bool {
            return true
        }
    }
}


struct EmbeddedContactPicker: UIViewControllerRepresentable {
    typealias UIViewControllerType = CNContactPickerViewController
    var contact: Binding<CNContact>

    class Coordinator: NSObject, CNContactPickerDelegate {
        var parent: EmbeddedContactPicker
        
        init(_ contactDetail: EmbeddedContactPicker) {
            self.parent = contactDetail
        }
        
        func contactPicker(_ picker: CNContactPickerViewController, didSelect contact: CNContact) {
            parent.contact.wrappedValue = contact
        }
        func contactPickerDidCancel(_ picker: CNContactPickerViewController) {
            
        }
    }

    func makeCoordinator() -> Coordinator {
        return Coordinator(self)
    }

    func makeUIViewController(context: UIViewControllerRepresentableContext<EmbeddedContactPicker>) -> EmbeddedContactPicker.UIViewControllerType {
        let controller = CNContactPickerViewController()
        controller.delegate = context.coordinator
        return controller
//        let result = EmbeddedContactPicker.UIViewControllerType()
//        result.delegate = context.coordinator
//        return result
    }
    
    func updateUIViewController(_ uiViewController: EmbeddedContactPicker.UIViewControllerType, context: UIViewControllerRepresentableContext<EmbeddedContactPicker>) { }

}

//class EmbeddedContactPickerViewController: UIViewController, CNContactPickerDelegate {
////    weak var delegate: EmbeddedContactPickerViewControllerDelegate?
//    
//    override func viewWillAppear(_ animated: Bool) {
//        super.viewWillAppear(animated)
//        self.open(animated: animated)
//    }
//    
//    private func open(animated: Bool) {
//        let viewController = CNContactPickerViewController()
//        viewController.delegate = self
//        self.present(viewController, animated: false)
//    }
//    
//    func contactPickerDidCancel(_ picker: CNContactPickerViewController) {
//        self.dismiss(animated: false) {
////            self.delegate?.embeddedContactPickerViewControllerDidCancel(self)
//        }
//    }
//    
//    func contactPicker(_ picker: CNContactPickerViewController, didSelect contact: CNContact) {
//        self.dismiss(animated: false) {
////            self.delegate?.embeddedContactPickerViewController(self, didSelect: contact)
//        }
//    }
//    
//}
