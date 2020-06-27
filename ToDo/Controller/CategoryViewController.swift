//
//  CategoryTableViewController.swift
//  ToDo
//
//  Created by Vahram Tadevosian on 6/27/20.
//  Copyright © 2020 Vahram Tadevosian. All rights reserved.
//

import UIKit
import CoreData

class CategoryViewController: SwipeTableViewController {

    let context = (UIApplication.shared.delegate as? AppDelegate)?.persistentContainer.viewContext
    var categories: [Category] = []
        
    override func viewDidLoad() {
        super.viewDidLoad()
        loadCategories()
    }

    @IBAction func addButtonTapped(_ sender: Any) {
        var textField = UITextField()
        
        let alert = UIAlertController(title: "Add New Category", message: "", preferredStyle: .alert)
        let action = UIAlertAction(title: "Add", style: .default) { (action) in
            guard let categoryName = textField.text, !categoryName.isEmpty,
                let context = self.context else { return }
            
            let newCategory = Category(context: context)
            newCategory.name = categoryName
            self.categories.append(newCategory)
            self.saveCategories()
        }
        
        alert.addTextField { (alertTextField) in
            alertTextField.placeholder = "Create new item"
            textField = alertTextField
        }
        
        alert.addAction(action)
        present(alert, animated: true, completion: nil)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard let destinationVC = segue.destination as? ToDoListViewController,
            let indexPath = tableView.indexPathForSelectedRow else { return }
        destinationVC.category = categories[indexPath.row]
    }
    
    // MARK: - Data Manipulation
    
    private func saveCategories() {
        do {
            try context?.save()
        } catch {
            print("Error while saving context: \(error).")
        }
        
        tableView.reloadData()
    }
    
    private func loadCategories(with request: NSFetchRequest<Category> = Category.fetchRequest()) {
        do {
            categories = try context?.fetch(request) ?? []
        } catch {
            print("Error fetching data from context: \(error).")
        }
        
        tableView.reloadData()
    }
    
    // MARK: - Data Deletion from Swipe
    
    override func updateModel(at indexPath: IndexPath) {
        context?.delete(categories[indexPath.row])
        categories.remove(at: indexPath.row)
    }
}

// MARK: - UITableViewDataSource

extension CategoryViewController {
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return categories.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = super.tableView(tableView, cellForRowAt: indexPath)
        cell.textLabel?.text = categories[indexPath.row].name
        return cell
    }
    
}

// MARK: - UITableViewDelegate

extension CategoryViewController {
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        performSegue(withIdentifier: "GoToItems", sender: self)
    }
}
