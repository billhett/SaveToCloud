//
//  ViewController.swift
//  SaveToCloud
//
//  Created by William Hettinger on 3/4/18.
//  Copyright © 2018 William Hettinger. All rights reserved.
//

import UIKit
import CloudKit

class ViewController: UIViewController {

    let database = CKContainer.default().privateCloudDatabase
    
    var notes = [CKRecord]()
    
    @IBOutlet weak var tableView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let refreshControl = UIRefreshControl()
        refreshControl.attributedTitle = NSAttributedString(string: "Pull to refresh")
        refreshControl.addTarget(self, action: #selector(queryDatabase), for: .valueChanged)
        self.tableView.refreshControl = refreshControl
        queryDatabase()
    }

    @IBAction func onPlusTapped() {
        var text = ""
        let alert = UIAlertController(title: "Thpe Something", message: "What would you like to save in a note", preferredStyle: .alert)
        
        alert.addTextField { (textField) in
            textField.placeholder = "Type note here"
            
        }
        let cancel = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        let post = UIAlertAction(title: "Post", style: .default) { (_) in
            guard let text = alert.textFields?.first?.text else { return }
            print("text is : \(text)")
            self.saveToCloud(note: text)
        }
        alert.addAction(cancel)
        alert.addAction(post)
        present(alert, animated: true, completion: nil)
        
    }
    
    func saveToCloud(note: String) {
        print("in save to cloud")
        let newNote = CKRecord(recordType: "Note")
        newNote.setValue(note, forKey: "content")
        database.save(newNote) { (record, error) in
            print("error saving to cloud: \(String(describing: error))")
            guard record != nil else {return}
            print("saved record with note \(String(describing: record))")
            self.queryDatabase()
        }
    }
    
    @objc func queryDatabase() {
        let query = CKQuery(recordType: "note", predicate: NSPredicate(value: true))
        database.perform(query, inZoneWith: nil) { (records, _) in
            guard let records = records else { return }
            let sortedRecords = records.sorted(by: { $0.creationDate! < $1.creationDate! })
            self.notes = sortedRecords
            
            DispatchQueue.main.async {
                self.tableView.refreshControl?.endRefreshing()
                self.tableView.reloadData()
            }
        }
    }

}

extension ViewController: UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return notes.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell()
        let note = notes[indexPath.row].value(forKey: "content") as! String
        cell.textLabel?.text = note
        return cell
    }
}
