//
//  ViewController.swift
//  ToDo
//
//  Created by Vahram Tadevosian on 6/26/20.
//  Copyright © 2020 Vahram Tadevosian. All rights reserved.
//

import UIKit
import CoreData
import ChameleonFramework

class ToDoListViewController: SwipeTableViewController {

    let context = (UIApplication.shared.delegate as? AppDelegate)?.persistentContainer.viewContext
    var items: [Item] = []
    var category: Category? {
        didSet {
            loadItems()
        }
    }
    
    @IBOutlet weak var searchBar: UISearchBar!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        searchBar.delegate = self
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if let colorHex = category?.color,
            let color = UIColor(hexString: colorHex) {
            guard let navBar = navigationController?.navigationBar else {
                fatalError("Navigation controller does not exist")
            }
            
            let contrastColor = ContrastColorOf(color, returnFlat: true)
            title = category!.name
            navBar.barTintColor = color
            navBar.largeTitleTextAttributes = [
                NSAttributedString.Key.foregroundColor: UIColor(named: "systemWhite")
            ]
            
            navBar.tintColor = color
            searchBar.barTintColor = color
        }
    }
    
    // MARK: - Data Manipulation
    
    @IBAction func addButtonTapped(_ sender: UIBarButtonItem) {
        var textField = UITextField()
        
        let alert = UIAlertController(title: "Add New Item", message: "", preferredStyle: .alert)
        let action = UIAlertAction(title: "Add", style: .default) { (action) in
            guard let itemTitle = textField.text, !itemTitle.isEmpty,
                let context = self.context else { return }
            
            let newItem = Item(context: context)
            newItem.title = itemTitle
            newItem.done = false
            newItem.category = self.category
            self.items.append(newItem)
            self.saveItems()
        }
        
        alert.addTextField { (alertTextField) in
            alertTextField.placeholder = "Create new item"
            textField = alertTextField
        }
        
        alert.addAction(action)
        present(alert, animated: true, completion: nil)
    }
    
    private func saveItems() {
        do {
            try context?.save()
        } catch {
            print("Error while saving context: \(error).")
        }
        
        tableView.reloadData()
    }
    
    private func loadItems(with request: NSFetchRequest<Item> = Item.fetchRequest(),
                           predicate: NSPredicate? = nil) {
        guard let categoryName = category?.name else { return }
        
        let categoryPredicate = NSPredicate(format: "category.name MATCHES %@", categoryName)
        if let additionalPredicate = predicate {
            request.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [categoryPredicate, additionalPredicate])
        } else {
            request.predicate = categoryPredicate
        }
        
        do {
            items = try context?.fetch(request) ?? []
        } catch {
            print("Error fetching data from context: \(error).")
        }
        
        tableView.reloadData()
    }
    
    // MARK: - Data Deletion from Swipe
    
    override func updateModel(at indexPath: IndexPath) {
        context?.delete(items[indexPath.row])
        items.remove(at: indexPath.row)
    }
}

// MARK: - UITableViewDataSource

extension ToDoListViewController {
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return items.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = super.tableView(tableView, cellForRowAt: indexPath)
        let item = items[indexPath.row]
        cell.textLabel?.text = item.title
        cell.accessoryType = item.done ? .checkmark : .none
        if let categoryColor = UIColor(hexString: category?.color ?? "FFFFFF")?.darken(byPercentage: CGFloat(indexPath.row) / CGFloat(items.count * 2)) {
            
            let contrastColor = ContrastColorOf(categoryColor, returnFlat: true)
            cell.backgroundColor = categoryColor
            cell.textLabel?.textColor = contrastColor
            cell.tintColor = contrastColor
        }
        return cell
    }
}

// MARK: - UITableViewDelegate

extension ToDoListViewController {
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let item = items[indexPath.row]
        item.done = !item.done
        saveItems()
        tableView.deselectRow(at: indexPath, animated: true)
    }
}

// MARK: - UISearchBarDelegate

extension ToDoListViewController: UISearchBarDelegate {
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        guard let text = searchBar.text,
            !text.isEmpty else { return }
        let predicate = NSPredicate(format: "title CONTAINS[cd] %@", text)
        let request: NSFetchRequest<Item> = Item.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(key: "title", ascending: true)]
        loadItems(with: request, predicate: predicate)
        tableView.reloadData()
    }
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        if searchBar.text?.count == 0 {
            loadItems()
            DispatchQueue.main.async {
                searchBar.resignFirstResponder()
            }
        }
    }
}
