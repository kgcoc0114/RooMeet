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
            updateDataSource()
            self.noneLabel.isHidden = !self.chatRooms.isEmpty
        }
    }

    @IBOutlet weak var tableView: UITableView! {
        didSet {
            tableView.separatorStyle = .none
            tableView.showsVerticalScrollIndicator = false
            tableView.delegate = self
            tableView.register(
                UINib(nibName: ChatRoomCell.reuseIdentifier, bundle: nil),
                forCellReuseIdentifier: ChatRoomCell.reuseIdentifier
            )
        }
    }

    @IBOutlet weak var noneLabel: UILabel! {
        didSet {
            noneLabel.font = UIFont.regularSubTitle()
            noneLabel.textColor = .mainDarkColor
            noneLabel.text = "目前還沒有聊天室唷！"
            noneLabel.isHidden = true
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.title = "Chat"
        configureDataSource()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        FirebaseService.shared.listenToChatRoomUpdate {[weak self] chatRooms, error in
            if let error = error {
                print(
                    "ERROR: FirebaseService listenToChatRoomUpdate",
                    error.localizedDescription
                )
            }

            if let chatRooms = chatRooms {
                DispatchQueue.main.async {
                    self?.chatRooms = chatRooms
                }
            }
        }
    }
}

extension ChatRoomListViewController {
    private func configureDataSource() {
        dataSource = DataSource(tableView: tableView) { tableView, indexPath, chatRoom in
            guard let cell = tableView.dequeueReusableCell(
                withIdentifier: ChatRoomCell.reuseIdentifier,
                for: indexPath
            ) as? ChatRoomCell else {
                return UITableViewCell()
            }
            cell.layoutCell(UserDefaults.id, chatRoom: chatRoom)
            return cell
        }
    }
}

extension ChatRoomListViewController {
    private func updateDataSource() {
        var newSnapshot = Snapshot()
        newSnapshot.appendSections(Section.allCases)
        newSnapshot.appendItems(chatRooms, toSection: .chatRoom)
        dataSource.apply(newSnapshot, animatingDifferences: false)
    }
}

extension ChatRoomListViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let chatRoom = chatRooms[indexPath.item]
        let detailVC = ChatViewController()
        detailVC.setup(chatRoom: chatRoom)
        self.hidesBottomBarWhenPushed = true
        DispatchQueue.main.async {
            self.hidesBottomBarWhenPushed = false
        }
        navigationController?.pushViewController(detailVC, animated: false)
    }
}
