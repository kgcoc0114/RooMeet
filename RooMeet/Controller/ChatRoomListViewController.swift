//
//  ChatRoomViewController.swift
//  RooMeet
//
//  Created by kgcoc on 2022/11/3.
//

import UIKit
import FirebaseFirestore

class ChatRoomListViewController: UIViewController {
    enum Section: CaseIterable {
        case chatRoom
    }

    enum Item: Hashable {
        case chatRoom(ChatRoom)
    }

    typealias DataSource = UITableViewDiffableDataSource<Section, ChatRoom>
    typealias Snapshot = NSDiffableDataSourceSnapshot<Section, ChatRoom>
    private var dataSource: DataSource!
    private var listener: ListenerRegistration?

    var chatRooms: [ChatRoom] = [] {
        didSet {
            print(updateDataSource)
            updateDataSource()
        }
    }

    @IBOutlet weak var tableView: UITableView! {
        didSet {
            tableView.delegate = self
            tableView.register(UINib(nibName: ChatRoomCell.reuseIdentifier, bundle: nil), forCellReuseIdentifier: ChatRoomCell.reuseIdentifier)
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.title = "聊天列表"
        print(User.mockUser.id)
        configureDataSource()
        FirebaseService.shared.fetchChatRoomDataWithMemberData(userID: User.mockUser.id) { [weak self] chatRooms in
            self?.chatRooms = chatRooms
        }
        updateDataSource()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        startListener()
    }
}

extension ChatRoomListViewController {
    private func configureDataSource() {
        dataSource = DataSource(tableView: tableView, cellProvider: { [unowned self] tableView, indexPath, itemIdentifier in
            guard let cell = tableView.dequeueReusableCell(withIdentifier: ChatRoomCell.reuseIdentifier, for: indexPath) as? ChatRoomCell else {
                return UITableViewCell()
            }
            let chatRoom = self.chatRooms[indexPath.item]
            cell.layoutCell(User.mockUser.id, chatRoom: chatRoom)
            return cell
        })
    }
}

extension ChatRoomListViewController {
    private func updateDataSource() {
        var newSnapshot = Snapshot()
        newSnapshot.appendSections(Section.allCases)
        newSnapshot.appendItems(chatRooms.map({ $0 }), toSection: .chatRoom)
        dataSource.apply(newSnapshot, animatingDifferences: true)
    }
}

extension ChatRoomListViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        print("eeeeeee")
        let chatRoom = chatRooms[indexPath.item]
        let detailVC = ChatViewController()
        detailVC.setup(chatRoom: chatRoom)
        navigationController?.pushViewController(detailVC, animated: true)
    }
}

extension ChatRoomListViewController {
    private func startListener() {
        listener = FirebaseService.shared.database.collection("ChatRoom").whereField("members", arrayContains: User.mockUser.id).order(by: "lastUpdated", descending: true)
            .addSnapshotListener({ querySnapshot, error in
                if let error = error {
                    print("Error getting documents: \(error)")
                }
                var chatRooms: [ChatRoom] = []
                if let querySnapshot = querySnapshot {
                    querySnapshot.documents.forEach { document in
                        do {
                            let item = try document.data(as: ChatRoom.self)
                            chatRooms.append(item)
                        } catch let DecodingError.dataCorrupted(context) {
                            print(context)
                        } catch let DecodingError.keyNotFound(key, context) {
                            print("Key '\(key)' not found:", context.debugDescription)
                            print("codingPath:", context.codingPath)
                        } catch let DecodingError.valueNotFound(value, context) {
                            print("Value '\(value)' not found:", context.debugDescription)
                            print("codingPath:", context.codingPath)
                        } catch let DecodingError.typeMismatch(type, context)  {
                            print("Type '\(type)' mismatch:", context.debugDescription)
                            print("codingPath:", context.codingPath)
                        } catch {
                            print("error: ", error)
                        }

                        //                    catch {
                        //                        print("DEBUG: Error decoding \(ChatRoom.self) data -", error.localizedDescription)
                        //                    }
                    }
                    self.chatRooms = chatRooms
                }
            })
    }
}
