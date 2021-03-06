//
//  ConversationsDisplayTests.swift
//  Conversations
//
//  Copyright © 2016 Bazaarvoice. All rights reserved.
//

import XCTest
@testable import BVSDK

class ConversationsDisplayTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        
        BVSDKManager.sharedManager().clientId = "apitestcustomer"
        BVSDKManager.sharedManager().apiKeyConversations = "kuy3zj9pr3n7i0wxajrzj04xo"
        BVSDKManager.sharedManager().staging = true
    }
    
    override func tearDown() {
        super.tearDown()
    }
    
    func testProductDisplay() {
        
        let expectation = expectationWithDescription("")
        
        let request = BVProductDisplayPageRequest(productId: "test1")
            .includeContent(PDPContentType.Reviews, limit: 10)
            .includeContent(.Reviews, limit: 10)
            .includeContent(.Questions, limit: 5)
            .includeStatistics(.Reviews)
        
        request.load({ (response) in
            
            XCTAssertNotNil(response.result)
            
            let product = response.result!
            let brand = product.brand!
            XCTAssertEqual(brand.identifier, "cskg0snv1x3chrqlde0zklodb")
            XCTAssertEqual(brand.name, "mysh")
            XCTAssertEqual(product.productDescription, "Our pinpoint oxford is crafted from only the finest 80\'s two-ply cotton fibers.Single-needle stitching on all seams for a smooth flat appearance. Tailored with our Traditional\n                straight collar and button cuffs. Machine wash. Imported.")
            XCTAssertEqual(product.brandExternalId, "cskg0snv1x3chrqlde0zklodb")
            XCTAssertEqual(product.imageUrl, "http://myshco.com/productImages/shirt.jpg")
            XCTAssertEqual(product.name, "Dress Shirt")
            XCTAssertEqual(product.categoryId, "testCategory1031")
            XCTAssertEqual(product.identifier, "test1")
            XCTAssertEqual(product.includedReviews.count, 10)
            XCTAssertEqual(product.includedQuestions.count, 5)
            expectation.fulfill()
            
        }) { (error) in
            
            XCTFail("product display request error: \(error)")
            expectation.fulfill()
            
        }
        
        self.waitForExpectationsWithTimeout(10) { (error) in
            XCTAssertNil(error, "Something went horribly wrong, request took too long.")
        }
        
    }
    
    func testReviewDisplay() {
        
        let expectation = expectationWithDescription("")
        
        let request = BVReviewsRequest(productId: "test1", limit: 10, offset: 0)
            .addSort(.Rating, order: .Ascending)
            .addFilter(.HasPhotos, filterOperator: .EqualTo, value: "true")
            .addFilter(.HasComments, filterOperator: .EqualTo, value: "false")
        
        request.load({ (response) in
            
            XCTAssertEqual(response.results.count, 10)
            let review = response.results.first!
            XCTAssertEqual(review.rating, 1)
            XCTAssertEqual(review.title, "Morbi nibh risus, mattis id placerat a massa nunc.")
            XCTAssertEqual(review.reviewText, "Lorem ipsum dolor sit amet, consectetur adipiscing elit. Sed rhoncus scelerisque semper. Morbi in sapien sit amet justo eleifend pellentesque! Cras sollicitudin, quam in ullamcorper faucibus, augue metus blandit justo, vitae ullamcorper tellus quam non purus. Fusce gravida rhoncus placerat. Integer tempus nunc sed elit mollis ut venenatis felis volutpat. Sed a velit et lacus lobortis aliquet? Donec dolor quam, pharetra vitae commodo et, mattis quis nibh? Quisque ultrices neque et lacus volutpat.")
            XCTAssertEqual(review.moderationStatus, "APPROVED")
            XCTAssertEqual(review.identifier, "191975")
            XCTAssertNil(review.product)
            XCTAssertEqual(review.isRatingsOnly, false)
            XCTAssertEqual(review.isFeatured, false)
            XCTAssertEqual(review.productId, "test1")
            XCTAssertEqual(review.authorId, "endersgame")
            XCTAssertEqual(review.userNickname, "endersgame")
            XCTAssertEqual(review.userLocation, "San Fransisco, California")
            
            XCTAssertEqual(review.tagDimensions!["Pro"]!.label, "Pros")
            XCTAssertEqual(review.tagDimensions!["Pro"]!.identifier, "Pro")
            XCTAssertEqual(review.tagDimensions!["Pro"]!.values!, ["Organic Fabric", "Quality"])
            
            XCTAssertEqual(review.photos.count, 1)
            XCTAssertEqual(review.photos.first?.caption, "Etiam malesuada ultricies urna in scelerisque. Sed viverra blandit nibh non egestas. Sed rhoncus, ipsum in vehicula imperdiet, purus lectus sodales erat, eget ornare lacus lectus ac leo. Suspendisse tristique sollicitudin ultricies. Aliquam erat volutpat.")
            XCTAssertEqual(review.photos.first?.identifier, "72586")
            XCTAssertEqual(review.photos.first?.sizes?.thumbnailUrl, "https://reviews.apitestcustomer.bazaarvoice.com/bvstaging/5556/72586/photoThumb.jpg")
            XCTAssertEqual(review.photos.first?.sizes?.normalUrl, "https://reviews.apitestcustomer.bazaarvoice.com/bvstaging/5556/72586/photo.jpg")
            
            XCTAssertEqual(review.contextDataValues.count, 1)
            let cdv = review.contextDataValues.first!
            XCTAssertEqual(cdv.value, "Female")
            XCTAssertEqual(cdv.valueLabel, "Female")
            XCTAssertEqual(cdv.dimensionLabel, "Gender")
            XCTAssertEqual(cdv.identifier, "Gender")
            
            XCTAssertEqual(review.badges.first?.badgeType, BVBadgeType.Merit)
            XCTAssertEqual(review.badges.first?.identifier, "top10Contributor")
            XCTAssertEqual(review.badges.first?.contentType, "REVIEW")
            
            response.results.forEach { (review) in
                XCTAssertEqual(review.productId, "test1")
            }
            
            expectation.fulfill()
            
        }) { (error) in
            
            XCTFail("product display request error: \(error)")
            
        }
        
        self.waitForExpectationsWithTimeout(10) { (error) in
            XCTAssertNil(error, "Something went horribly wrong, request took too long.")
        }
        
    }
    
    func testQuestionDisplay() {
        
        let expectation = expectationWithDescription("")
        
        let request = BVQuestionsAndAnswersRequest(productId: "test1", limit: 10, offset: 0)
            .addFilter(.HasAnswers, filterOperator: .EqualTo, value: "true")
        
        request.load({ (response) in
        
            XCTAssertEqual(response.results.count, 10)
            
            let question = response.results.first!
            XCTAssertEqual(question.questionSummary, "Das ist mein test :)")
            XCTAssertEqual(question.questionDetails, "Das ist mein test :)")
            XCTAssertEqual(question.userNickname, "123thisisme")
            XCTAssertEqual(question.authorId, "eplz083100g")
            XCTAssertEqual(question.moderationStatus, "APPROVED")
            XCTAssertEqual(question.identifier, "14828")
            
            XCTAssertEqual(question.answers.count, 1)
            
            let answer = question.answers.first!
            XCTAssertEqual(answer.userNickname, "asdfasdfasdfasdf")
            XCTAssertEqual(answer.questionId, "14828")
            XCTAssertEqual(answer.authorId, "c6ryqeb2bq0")
            XCTAssertEqual(answer.moderationStatus, "APPROVED")
            XCTAssertEqual(answer.identifier, "16292")
            XCTAssertEqual(answer.answerText, "zxnc,vznxc osaidmf oaismdfo ims adoifmaosidmfoiamsdfimasdf")
            
            response.results.forEach { (question) in
                XCTAssertEqual(question.productId, "test1")
            }
            
            expectation.fulfill()
        
        }) { (error) in
         
            XCTFail("product display request error: \(error)")
            expectation.fulfill()
        
        }
        
        self.waitForExpectationsWithTimeout(10) { (error) in
            XCTAssertNil(error, "Something went horribly wrong, request took too long.")
        }
        
    }
    
    
    func testInlineRatingsDisplayOneProduct() {
        
        let expectation = expectationWithDescription("")
        
        let request = BVBulkRatingsRequest(productIds: ["test3"], statistics: .All)
        request.addFilter(.ContentLocale, filterOperator: .EqualTo, values: ["en_US"])
        
        request.load({ (response) in
            XCTAssertEqual(response.results.count, 1)
            XCTAssertEqual(response.results[0].productId, "test3")
            XCTAssertEqual(response.results[0].reviewStatistics?.totalReviewCount, 29)
            XCTAssertNotNil(response.results[0].reviewStatistics?.averageOverallRating)
            XCTAssertEqual(response.results[0].reviewStatistics?.overallRatingRange, 5)
            XCTAssertEqual(response.results[0].nativeReviewStatistics?.totalReviewCount, 29)
            XCTAssertEqual(response.results[0].nativeReviewStatistics?.overallRatingRange, 5)
            expectation.fulfill()
        }) { (error) in
            XCTFail("inline ratings request error: \(error)")
            expectation.fulfill()
        }
        
        self.waitForExpectationsWithTimeout(10) { (error) in
            XCTAssertNil(error, "Something went horribly wrong, request took too long.")
        }
        
    }
    
    func testInlineRatingsDisplayMultipleProducts() {
        
        let expectation = expectationWithDescription("")
        
        let request = BVBulkRatingsRequest(productIds: ["test1", "test2", "test3"], statistics: .All)
        request.addFilter(.ContentLocale, filterOperator: .EqualTo, values: ["en_US"])
        
        request.load({ (response) in
            XCTAssertEqual(response.results.count, 3)
            expectation.fulfill()
        }) { (error) in
            XCTFail("inline ratings request error: \(error)")
            expectation.fulfill()
        }
        
        self.waitForExpectationsWithTimeout(10) { (error) in print("request took way too long") }
    }
    
    func testInlineRatingsTooManyProductsError() {
        
        let expectation = expectationWithDescription("inline ratings display should complete")
        
        var tooManyProductIds: [String] = []
        
        for i in 0 ... 110{
            tooManyProductIds += [String(i)]
        }

        
        let request = BVBulkRatingsRequest(productIds: tooManyProductIds, statistics: .All)
        
        request.load({ (response) in
            XCTFail("Should not succeed")
        }) { (error) in
            expectation.fulfill()
        }
        
        self.waitForExpectationsWithTimeout(10) { (error) in
            XCTAssertNil(error, "Something went horribly wrong, request took too long.")
        }
        
    }

}
