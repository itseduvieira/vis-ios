//
//  TutorialController.swift
//  VisualNoAr
//
//  Created by Eduardo Vieira on 19/08/17.
//  Copyright © 2017 Visual no Ar. All rights reserved.
//

import UIKit

class TutorialController: UIPageViewController, UIPageViewControllerDataSource, UIPageViewControllerDelegate {
    
    //MARK: Properties
    lazy var pages: [UIViewController] = {
        return [self.getVCInstance(name: "FirstStepViewController"),
                self.getVCInstance(name: "SecondStepViewController"),
                self.getVCInstance(name: "ThirdStepViewController")]
    }()
    
    var index: Int = 0
    
    //MARK: Actions
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.dataSource = self
        self.delegate = self
        
        if let firstVC = pages.first {
            setViewControllers([firstVC], direction: .forward, animated: true, completion: nil)
        }
        
        (self.pages[0] as! PageController).parentVC = self
        (self.pages[1] as! PageController).parentVC = self
        (self.pages[2] as! PageController).parentVC = self
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        for view in self.view.subviews {
            if view is UIScrollView {
                view.frame = UIScreen.main.bounds
            } else if view is UIPageControl {
                let control = view as! UIPageControl
                control.backgroundColor = UIColor.clear
                control.currentPageIndicatorTintColor = UIColor(hexString: "#00BAE1")
                control.pageIndicatorTintColor = UIColor(hexString: "#000000").withAlphaComponent(0.3)
            }
        }
    }
    
    private func getVCInstance(name: String) -> UIViewController {
        return UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: name)
    }
    
    func nextPage() {
        index += 1
        
        if index >= pages.count {
            index = 0
        }
        
        setViewControllers([pages[index]], direction: .forward, animated: true, completion: nil)
    }
    
    public func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {
        guard let vcIndex = pages.index(of: viewController) else {
            return nil
        }
        
        let previousIndex = vcIndex - 1
        
        guard previousIndex >= 0 else {
            return pages.last
        }
        
        guard pages.count > previousIndex else {
            return nil
        }
        
        index = previousIndex
        
        return pages[previousIndex]
    }
    
    public func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
        guard let vcIndex = pages.index(of: viewController) else {
            return nil
        }
        
        let nextIndex = vcIndex + 1
        
        guard nextIndex < pages.count else {
            return pages.first
        }
        
        guard pages.count > nextIndex else {
            return nil
        }
        
        index = nextIndex
        
        return pages[nextIndex]
    }
    
    public func presentationCount(for pageViewController: UIPageViewController) -> Int {
        return pages.count
    }
    
    public func presentationIndex(for pageViewController: UIPageViewController) -> Int {
        guard let firstVC = viewControllers?.first, let firstVCIndex = pages.index(of: firstVC) else {
            return 0
        }
        
        return firstVCIndex
    }
}

