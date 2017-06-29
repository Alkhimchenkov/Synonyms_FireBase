//
//  SearchViewController.m
//  Synonyms
//
//  Created by Андрей on 24.06.17.
//  Copyright © 2017 Home. All rights reserved.
//

#import "SearchViewController.h"
#import "DataProvider.h"
#import "ApiData.h"


static NSString *const kTitle  = @"Search word";
static NSString *const kTitleResult  = @"Result";

@interface SearchViewController () <UISearchControllerDelegate, UISearchBarDelegate, UITableViewDelegate, UITableViewDataSource>

@property (nonatomic, strong) UISearchController *searchController;
@property (nonatomic, strong) NSArray *arraySearchResult;

@property (strong, nonatomic) IBOutlet UIBarButtonItem *saveButtonItem;
@property (strong, nonatomic) IBOutlet UIBarButtonItem *searchButtonItem;
@property (strong, nonatomic) IBOutlet UINavigationItem *myNavigationItem;

@property (strong, nonatomic) IBOutlet UITableView *resultSearhViewTable;


@end

@implementation SearchViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self.saveButtonItem setEnabled:NO];
    [self.myNavigationItem setTitle:kTitle];
    [self.resultSearhViewTable setDelegate:self];
    [self.resultSearhViewTable setDataSource:self];
    [self initializeSearchController];
}


#pragma mark - Navigation

#pragma mark - Action Navigation
-(IBAction)showSerchController:(id)sender{
    [self.myNavigationItem setLeftBarButtonItems:nil];
    [self.myNavigationItem setRightBarButtonItem:nil];
    [self.myNavigationItem setTitleView:self.searchController.searchBar];
    [self.searchController setActive:YES];
}


-(IBAction)saveSearchResult:(id)sender{
    [self.saveButtonItem setEnabled:YES];
}

#pragma mark - custom method Navigation
- (void)initializeSearchController {
    self.searchController = [[UISearchController alloc] initWithSearchResultsController:nil];
    [self.searchController.searchBar sizeToFit];
    [self.searchController setHidesNavigationBarDuringPresentation:NO];
    [self.searchController.searchBar setSearchBarStyle:UISearchBarStyleMinimal];
    [self.searchController.searchBar setDelegate:self];
    [self setDefinesPresentationContext:YES];
    [self.searchController setDelegate:self];
    [self.searchController setDimsBackgroundDuringPresentation:NO];
}


#pragma mark - delegate methods UISearchControllerDelegate
- (void)didPresentSearchController:(UISearchController *)searchController{
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.searchController.searchBar becomeFirstResponder];
    });
}
- (void)willDismissSearchController:(UISearchController *)searchController{
    [self.myNavigationItem setRightBarButtonItem:self.saveButtonItem];
    [self.myNavigationItem setRightBarButtonItem:self.searchButtonItem];
    [self.myNavigationItem setTitleView:nil];
}


#pragma mark - delegate methods UISearchBarDelegate
- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar{
 
    __block NSString *keyDictionary = [self.searchController.searchBar.text lowercaseString];
    
    keyDictionary = [NSString stringWithFormat:@"%@%@",[[keyDictionary substringToIndex:1] uppercaseString],[keyDictionary substringFromIndex:1] ];
    
    [self.myNavigationItem setTitle:[NSString stringWithFormat:@"%@: %@",kTitleResult, keyDictionary]];

    [[DataProvider sharedInstance] setHistoryRequest:keyDictionary];
    
    ApiData *apiData = [[ApiData alloc] init];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        
        if ([apiData requestFromServer:[ApiData getUrl:self.searchController.searchBar.text]]) {

            NSArray *keys = [apiData.dataRequest allKeys];
            NSMutableArray *wordArray = [[NSMutableArray alloc] init];
        
            for (NSString *key in keys) {
                [wordArray addObjectsFromArray:apiData.dataRequest[key][@"syn"]];
            }
            
            if ([[DataProvider sharedInstance] getActiveSave:keyDictionary]) {
                [[DataProvider sharedInstance] addSaveData:@[@{keyDictionary:wordArray}]];
                [apiData updateFireBase:keyDictionary data:wordArray];
            }
            
            dispatch_async(dispatch_get_main_queue(), ^{
            self.arraySearchResult =  wordArray;
            [self.resultSearhViewTable reloadData];
         });
        
        }
    });
    
    [self.searchController setActive:NO];
}


- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar{
    [self.myNavigationItem setTitle:kTitle];
}


#pragma  mark - UITableView
#pragma mark - Delegate UITableViewDataSource
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [self.arraySearchResult count];
}

#pragma mark - Delegate UITableViewDelegate
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *identifier = @"Cell";
    
    UITableViewCell *cell = [self.resultSearhViewTable dequeueReusableCellWithIdentifier:identifier forIndexPath:indexPath];
    [cell.textLabel setText:[self.arraySearchResult objectAtIndex:indexPath.row]];
    return cell;
}

@end
