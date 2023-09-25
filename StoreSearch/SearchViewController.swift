//
//  ViewController.swift
//  StoreSearch
//
//  Created by Tyler Gerard on 9/24/23.
//

import UIKit

class SearchViewController: UIViewController {
    
    //if needing to change reuse identifer it can be done here
    struct TableView {
      struct CellIdentifiers {
        static let searchResultCell = "SearchResultCell"
          static let nothingFoundCell = "NothingFoundCell"
          static let loadingCell = "LoadingCell"

      }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.contentInset = UIEdgeInsets(top: 51, left: 0, bottom:
        0, right: 0)
        var cellNib = UINib(nibName: TableView.CellIdentifiers.searchResultCell, bundle: nil)
        tableView.register(cellNib, forCellReuseIdentifier:
        TableView.CellIdentifiers.searchResultCell)
        cellNib = UINib(nibName: TableView.CellIdentifiers.nothingFoundCell, bundle: nil)
        tableView.register(
        cellNib,
          forCellReuseIdentifier:
        TableView.CellIdentifiers.nothingFoundCell)
        searchBar.becomeFirstResponder()
        cellNib = UINib(
          nibName: TableView.CellIdentifiers.loadingCell, bundle: nil)
        tableView.register(
          cellNib,
          forCellReuseIdentifier: TableView.CellIdentifiers.loadingCell)
    }

    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var tableView: UITableView!
    
    var hasSearched = false
    var isLoading = false
    var searchResults = [SearchResult]()
    
    //create http request
    // MARK: - Helper Methods
    func iTunesURL(searchText: String) -> URL {
        let encodedText = searchText.addingPercentEncoding(
              withAllowedCharacters: CharacterSet.urlQueryAllowed)!
        let urlString = String(
            format: "https://itunes.apple.com/search?term=%@",
            encodedText) 
      let url = URL(string: urlString)
      return url!
    }
    
    //send http request
    func performStoreRequest(with url: URL) -> Data? {
      do {
          return try Data(contentsOf:url)
      } catch {
       print("Download Error: \(error.localizedDescription)")
          showNetworkError()
    return nil
    } }
    
    //parse JSON
    func parse(data: Data) -> [SearchResult] {
      do {
        let decoder = JSONDecoder()
        let result = try decoder.decode(
          ResultArray.self, from: data)
        return result.results
      } catch {
        print("JSON Error: \(error)")
    return [] }
    }

    //error handling
    func showNetworkError() {
      let alert = UIAlertController(
        title: "Whoops...",
        message: "There was an error accessing the iTunes Store." +
        " Please try again.",
        preferredStyle: .alert)
    let action = UIAlertAction(
        title: "OK", style: .default, handler: nil)
      alert.addAction(action)
      present(alert, animated: true, completion: nil)
    }
}

//Delegate methods
// MARK: - Search Bar Delegate
extension SearchViewController: UISearchBarDelegate {
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
      if !searchBar.text!.isEmpty {
        searchBar.resignFirstResponder()
          isLoading = true
          tableView.reloadData()
        hasSearched = true
        searchResults = []
          // 1
          let queue = DispatchQueue.global()
          let url = self.iTunesURL(searchText: searchBar.text!) // 2
          queue.async {
                if let data = self.performStoreRequest(with: url) {
                  self.searchResults = self.parse(data: data)
                  self.searchResults.sort(by: <)
                  // 3
                    DispatchQueue.main.async {
                      self.isLoading = false
                      self.tableView.reloadData()
                    }
          return
          }
          }
          }
    }
    func position(for bar: UIBarPositioning) -> UIBarPosition {
      return .topAttached
    }
}

// MARK: - Table View Delegate
extension SearchViewController: UITableViewDelegate,
                                UITableViewDataSource {
    func tableView(
        _ tableView: UITableView,
        numberOfRowsInSection section: Int
    ) -> Int {
        if isLoading {
            return 1
          } else if !hasSearched {
            return 1
        } else {
            return searchResults.count
        }
    }
    
    func tableView(
      _ tableView: UITableView,
      cellForRowAt indexPath: IndexPath
    ) -> UITableViewCell {
        if isLoading {
            let cell = tableView.dequeueReusableCell(
              withIdentifier: TableView.CellIdentifiers.loadingCell,
              for: indexPath)
            let spinner = cell.viewWithTag(100) as!
        UIActivityIndicatorView
            spinner.startAnimating()
            return cell
        } else
      if searchResults.count == 0 {
        return tableView.dequeueReusableCell(
          withIdentifier:
    TableView.CellIdentifiers.nothingFoundCell,
          for: indexPath)
      } else {
        let cell = tableView.dequeueReusableCell(withIdentifier:
          TableView.CellIdentifiers.searchResultCell,
          for: indexPath) as! SearchResultCell
        let searchResult = searchResults[indexPath.row]
        cell.nameLabel.text = searchResult.name
          if searchResult.artist.isEmpty {
            cell.artistNameLabel.text = "Unknown"
          } else {
            cell.artistNameLabel.text = String(
              format: "%@ (%@)",
              searchResult.artist,
              searchResult.type)
          }
          return cell
    } }


    func tableView(
      _ tableView: UITableView,
      didSelectRowAt indexPath: IndexPath
    ){
    tableView.deselectRow(at: indexPath, animated: true)
    }
    
    func tableView(
      _ tableView: UITableView,
      willSelectRowAt indexPath: IndexPath
    ) -> IndexPath? {
      if searchResults.count == 0 || isLoading{
        return nil
      } else {
        return indexPath
      }
    }
}
