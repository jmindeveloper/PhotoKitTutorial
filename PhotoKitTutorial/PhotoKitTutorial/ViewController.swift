//
//  ViewController.swift
//  PhotoKitTutorial
//
//  Created by J_Min on 2022/05/20.
//

import UIKit
import Photos

class ViewController: UIViewController {
    
    var assets: PHFetchResult<PHAsset>? = nil {
        willSet {
            OperationQueue.main.addOperation { [weak self] in
                self?.collectionView.reloadData()
            }
        }
    }
    @IBOutlet weak var collectionView: UICollectionView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        checkAuthrization()
        
        collectionView.dataSource = self
        collectionView.delegate = self
        PHPhotoLibrary.shared().register(self)
        
    }
    
    // MARK: - Method
    // 사진앱 접근권한 상태
    private func checkAuthrization() {
        let photoAuthorizationStatus = PHPhotoLibrary.authorizationStatus()
        
        switch photoAuthorizationStatus {
        case .authorized:
            print("인증됨")
            // 인증된 상태일경우 사진을 가져옴
            fetchAllAssets()
        case .notDetermined:
            PHPhotoLibrary.requestAuthorization { [weak self] status in
                guard let self = self else { return }
                switch status {
                case .authorized:
                    print("인증됨")
                    self.fetchAllAssets()
                default:
                    break
                }
            }
        default:
            return
        }
    }
    
    // 전체 사진(PHAsset) 가져오기
    private func fetchAllAssets() {
        let fetchOptions = PHFetchOptions()
        fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        assets = PHAsset.fetchAssets(with: fetchOptions)
    }
}

// PhotoKit 기타 기능들
extension ViewController {
    // 삭제
    private func deleteAsset(_ asset: [PHAsset]) {
        PHPhotoLibrary.shared().performChanges {
            PHAssetChangeRequest.deleteAssets(asset as NSArray)
        }
    }
    
    // 사진 업데이트(즐겨찾기)
    private func favoriteAsset(_ asset: PHAsset) {
        PHPhotoLibrary.shared().performChanges {
            let request = PHAssetChangeRequest(for: asset)
            request.isFavorite = !request.isFavorite
        }
    }
    
    // 사진 추가
    private func addAsset() {
        PHPhotoLibrary.shared().performChanges {
            PHAssetChangeRequest.creationRequestForAsset(from: UIImage(systemName: "person.fill")!)
        }
    }
}

// 사진앱 변화 실시간 반영
extension ViewController: PHPhotoLibraryChangeObserver {
    func photoLibraryDidChange(_ changeInstance: PHChange) {
        guard let change = changeInstance.changeDetails(for: assets!)?.fetchResultAfterChanges else { return }
        assets = change
        OperationQueue.main.addOperation { [weak self] in
            self?.collectionView.reloadData()
        }
    }
}


extension ViewController: UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        // assets이 없으면 0개의 셀을 표시해라
        return assets?.count ?? 0
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: String(describing: ImageCell.self), for: indexPath) as! ImageCell
        
        guard let assets = assets else { return UICollectionViewCell() }
        // PHAsset 하나 가져오기
        let asset = assets[indexPath.item]
        // targetSize
        let targetSize = CGSize(width: 360, height: 360)
        // requestOptions
        let requestOptions = PHImageRequestOptions()
        // 이미지 품질
        requestOptions.deliveryMode = .highQualityFormat
        // 이미지 리사이즈
        requestOptions.resizeMode = .none
        // 이미지 동기로 가져욤?
        requestOptions.isSynchronous = true
        
        PHImageManager.default().requestImage(for: asset, targetSize: targetSize, contentMode: .aspectFill, options: requestOptions) { image, _ in
            DispatchQueue.main.async {            
                cell.ImageView.image = image
            }
        }
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        0
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        0
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let frame = self.view.safeAreaLayoutGuide.layoutFrame
        let width = (frame.width / 3)

        return CGSize(width: width, height: width)
    }
}





// cell
class ImageCell: UICollectionViewCell {
    @IBOutlet weak var ImageView: UIImageView!
}
