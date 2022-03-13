//
//  ToDoListTVC.swift
//  CoreDataApp
//
//  Created by Dmitry on 9.03.22.
//

import UIKit
import CoreData

class TaskListTVC: UITableViewController {
    
    let storage = Storage.shared
    let context = Storage.shared.context
    var addTaskAV: UIView?
    var tasks: [[Task]] = [[]]
    
    var selectedCategory: Category? {
        didSet {
            self.title = selectedCategory?.name
            loadTasks()
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        loadTasks()
        configureBarButtonItem()
        
        self.clearsSelectionOnViewWillAppear = false
    }
    
    @objc func addTaskAction(_ sender: Any) {
        
        let alert = UIAlertController(title: "Add task",
                                      message: "",
                                      preferredStyle: .alert)
        let priorityPickerView = UIPickerView(frame: CGRect(x: 5, y: 20, width: 250, height: 140))

        alert.addTextField { textField in
            textField.placeholder = "Category"
        }

        alert.addAction(UIAlertAction(title: "Select task priority", style: .default, handler: { [weak self] _ in

            if let textField = alert.textFields?.first,
               let text = textField.text,
               text != "",
               let context = self?.context {

                let newTask = Task(context: context)
                newTask.title = text
                newTask.parentCategory = self?.selectedCategory

                self?.selectTaskPriority(for: newTask)
            }

        }))
        alert.addAction(UIAlertAction(title: "Cancel", style: .destructive))

        self.present(alert, animated: true)
    }

    private func selectTaskPriority(for task: Task) {
        
        let width: CGFloat = UIScreen.main.bounds.width - 20
        let height: CGFloat = 100
        let margin: CGFloat = 10
        let vc = UIViewController()
        
        let priorityPickerView = UIPickerView(frame: CGRect(x: margin, y: margin, width: width - 20, height: height))
    
        priorityPickerView.dataSource = self
        priorityPickerView.delegate = self
        
        vc.view.addSubview(priorityPickerView)
        
        priorityPickerView.selectRow(TaskPriority.allCases.count / 2, inComponent: 0, animated: false)
        
        priorityPickerView.centerXAnchor.constraint(equalTo: vc.view.centerXAnchor).isActive = true
        priorityPickerView.centerYAnchor.constraint(equalTo: vc.view.centerYAnchor).isActive = true
        
        let alert = UIAlertController(title: "Select task priority", message: "", preferredStyle: .actionSheet)
        alert.setValue(vc, forKey: "contentViewController")
        
        alert.addAction(UIAlertAction(title: "Save", style: .default, handler: { [weak self] _ in
            if let context = self?.context {
                let priority = Priority(context: context)
                
                let priorityIndex = priorityPickerView.selectedRow(inComponent: 0)
                let priorityName = TaskPriority.allCases[priorityIndex].rawValue
                
                priority.name = priorityName
                
                task.priority = priority
                
                self?.tasks[priorityIndex].append(task)
                self?.storage.saveContext()
                let indexNewTask = (self?.tasks[priorityIndex].count)! - 1
                self?.tableView.insertRows(at: [IndexPath(row: indexNewTask, section: priorityIndex)], with: .automatic)
            }
        }))
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .destructive))
        
        self.present(alert, animated: true)
    }
    
    private func configureBarButtonItem() {
        let plusImage = UIImage(systemName: "plus")
        let plusButton = UIBarButtonItem(image: plusImage,
                                         style: .plain,
                                         target: self,
                                         action: #selector(addTaskAction))

        self.navigationItem.rightBarButtonItems = [plusButton, self.editButtonItem]
        
    }
    
    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return TaskPriority.allCases.count
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return tasks[section].count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: Constants.reuseIdentifier, for: indexPath)
        
        let task = tasks[indexPath.section][indexPath.row]
        cell.textLabel?.text = task.title
        cell.accessoryType = task.isDone ? .checkmark : .none
        return cell
    }
    
    // MARK: - Table view delegate
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        tasks[indexPath.section][indexPath.row].isDone.toggle()
        self.storage.saveContext()
        tableView.reloadRows(at: [indexPath], with: .fade)
    }
    
    override func tableView(_ tableView: UITableView, moveRowAt fromIndexPath: IndexPath, to: IndexPath) {

        let currentTask = tasks[fromIndexPath.section].remove(at: fromIndexPath.row)
        let newPriorityName = TaskPriority.allCases[to.section].rawValue
        currentTask.priority?.name = newPriorityName
        tasks[to.section].insert(currentTask, at: to.row)
        loadTasks()
    }
    
    override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return TaskPriority.allCases[section].rawValue
    }
    
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        
        let currentTask = tasks[indexPath.section][indexPath.row]
        
        if editingStyle == .delete {
            tasks[indexPath.section].remove(at: indexPath.row)
            tableView.deleteRows(at: [indexPath], with: .automatic)
            context.delete(currentTask)
        }
        
    }
    
    // MARK: - Core Data
    
    private func loadTasks(with request: NSFetchRequest<Task> = Task.fetchRequest(),
                           predicatate: NSPredicate? = nil) {

        guard let name = selectedCategory?.name else { return }
        let categoryPredicate = NSPredicate(format: "parentCategory.name MATCHES %@", name)

        if let predicate = predicatate {
            request.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [predicate, categoryPredicate])

        } else {
            request.predicate = categoryPredicate
        }

        do {
            let allTasks = try context.fetch(request)
        
            for (index, priority) in TaskPriority.allCases.enumerated() {
                tasks.append([Task]())
                tasks[index] = allTasks[priority]
            }
           
        } catch {
            print("Error fetch context")
        }

        tableView.reloadData()
    }
}

extension TaskListTVC: UISearchBarDelegate {
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        if searchText.isEmpty {
            loadTasks()
            searchBar.resignFirstResponder()
        } else {
            let request: NSFetchRequest<Task> = Task.fetchRequest()
            let searchPredicate = NSPredicate(format: "title CONTAINS %@", searchText)
            request.sortDescriptors = [NSSortDescriptor(key: "title", ascending: true)]
            loadTasks(with: request, predicatate: searchPredicate)
        }
    }
}

extension TaskListTVC: UIPickerViewDelegate, UIPickerViewDataSource {
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return TaskPriority.allCases.count
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return TaskPriority.allCases[row].rawValue
    }
}
