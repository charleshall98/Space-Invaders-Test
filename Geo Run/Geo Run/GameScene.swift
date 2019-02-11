//
//  GameScene.swift
//  Space Invaders
//
//  Created by Charles Hall on 2/9/19.
//  Copyright © 2019 Charles Hall. All rights reserved.
//

import SpriteKit
import GameplayKit

class GameScene: SKScene, SKPhysicsContactDelegate {
    
    //Variables to track the score, lives, and levels
    var score = 0
    var lives = 3
    var level = 0
    
    //Labels for the score, lives, and levels
    let scoreLabel = SKLabelNode(fontNamed: "The Bold Font")
    let livesLabel = SKLabelNode(fontNamed: "The Bold Font")
    let levelLabel = SKLabelNode(fontNamed: "The Bold Font")
    
    let player = SKSpriteNode(imageNamed: "playerShip")//Grabs player ship image from Assets.xcassets
    let gameArea: CGRect//Sets the gameArea to a rectangle
    
    //Function to generate a random number
    func random() -> CGFloat {
        return CGFloat(Float(arc4random()) / 0xFFFFFFFF)
    }
    //Function to generate a random number within a certain bound
    func random(min: CGFloat, max: CGFloat) -> CGFloat {
        return random() * (max - min) + min
    }
   
    //Structure to hold our physics categories
    struct PhysicsCategories {
        static let None : UInt32 = 0
        static let Player : UInt32 = 0b1//Binary of 1
        static let Bullet : UInt32 = 0b10//Binary of 2
        static let Enemy : UInt32 = 0b100//Binary of 4
    }
    
    //Function to handle the contact logic when two phsyics bodies meet
    func didBegin(_ contact: SKPhysicsContact) {
        var body1 = SKPhysicsBody()//Body 1 is a physic body
        var body2 = SKPhysicsBody()//Body 2 is a physic body
        
        //Depending on the bit mask of the phsyic body...
        if contact.bodyA.categoryBitMask < contact.bodyB.categoryBitMask {
            body1 = contact.bodyA
            body2 = contact.bodyB
        }
        else {
            body1 = contact.bodyB
            body2 = contact.bodyA
        }
        
        //If the player hits the enemy...
        if(body1.categoryBitMask == PhysicsCategories.Player && body2.categoryBitMask == PhysicsCategories.Enemy) {
            lives -= 1//Update lives
            livesLabel.text = "Lives: \(lives)"//Display updated lives
            explode(spawnPosition: body1.node!.position)//Explosion is spawned at the position of the player
            explode(spawnPosition: body2.node!.position)//Explosion is spawned at the position of the enemy
            body1.node?.removeFromParent()//Remove the player
            body2.node?.removeFromParent()//Remove the enemy
        }
        //If the bullet has hit the enemy AND the enemy is on the screen...
        if(body1.categoryBitMask == PhysicsCategories.Bullet && body2.categoryBitMask == PhysicsCategories.Enemy && (body2.node?.position.y)! < self.size.height) {
            if(body2.node != nil) {//Makes sure the enemy isn't nothing
                explode(spawnPosition: body2.node!.position)//Explosion is spawned at the position of the enemy
            }
            score += 1//Update Score
            scoreLabel.text = "Score: \(score)"//Display updated Score
            //When the score meets a certain point, update the level
            if(score == 10 || score == 30 || score == 50) {
                startNewLevel()
            }
    
            body1.node?.removeFromParent()//Remove the bullet
            body2.node?.removeFromParent()//Remove the enemy
        }
    }
    
    //Overrides the init method to allow us to create the game area that the user can play in
    override init(size: CGSize) {
        let maxAspectRatio: CGFloat = 16.0 / 9.0//This is our max aspect ratio used to find the playable size
        let playableWidth = size.height / maxAspectRatio//This is how wide our playable area will be
        let margin = (size.width - playableWidth) / 2
        gameArea = CGRect(x: margin, y: 0, width: playableWidth, height: size.height)//Sets the game area
        super.init(size: size)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    //Overrides the didMove function to create the view of the app
    override func didMove(to view: SKView) {
        
        self.physicsWorld.contactDelegate = self//Allows us to use physics contacts in the scene
        //Code to initiate the background object
        let background = SKSpriteNode(imageNamed: "background")//Grabs background image from Assets.xcassets
        background.size = self.size//Background size is equal to scene size
        background.position = CGPoint(x: self.size.width/2, y: self.size.height/2)//Position of the background is in the center of the scene
        background.zPosition = 0//Layers the background at the lowest layer of the scene
        self.addChild(background)//Adds the background SkSpriteNode to the scene
        
        //Code to initiate the player object
        player.setScale(1)//Scale of the ship is "normal size" (2 would be double the size)
        player.position = CGPoint(x: self.size.width/2, y: self.size.height * 0.2)//Sets the ship position to the bottom of the scene
        player.zPosition = 2//Layers the ship on the second layer of the scene(Because the bullet will go on the first layer)
        player.physicsBody = SKPhysicsBody(rectangleOf: player.size)//Physics body is the size of the player ship
        player.physicsBody!.affectedByGravity = false//The player's ship will not be affected by gravity
        player.physicsBody!.categoryBitMask = PhysicsCategories.Player//The physics category is set to the Player's category
        player.physicsBody!.collisionBitMask = PhysicsCategories.None//The enemy should not collide with anything
        player.physicsBody!.contactTestBitMask = PhysicsCategories.Enemy//If the player makes contact with an enemy, let us know
        self.addChild(player)//Adds the player SKSpriteNode to the scene
        
        //Code for the score label
        scoreLabel.text = "Score: 0"
        scoreLabel.fontSize = 70
        scoreLabel.fontColor = SKColor.white
        scoreLabel.horizontalAlignmentMode = SKLabelHorizontalAlignmentMode.left
        scoreLabel.position = CGPoint(x: self.size.width * 0.15, y: self.size.height * 0.9)
        scoreLabel.zPosition = 4
        self.addChild(scoreLabel)
        
        //Code for the lives label
        livesLabel.text = "Lives: 3"
        livesLabel.fontSize = 70
        livesLabel.fontColor = SKColor.white
        livesLabel.horizontalAlignmentMode = SKLabelHorizontalAlignmentMode.right
        livesLabel.position = CGPoint(x: self.size.width * 0.85, y: self.size.height * 0.9)
        livesLabel.zPosition = 4
        self.addChild(livesLabel)
        
        startNewLevel()
    }
    
    //Function to handle the logic when firing a bullet
    func fireBullet() {
        let bullet = SKSpriteNode(imageNamed: "bullet")//Grabs the bullet image from Assets.xcassets
        bullet.setScale(1)//Scale of the bullet is "normal"
        bullet.position = player.position
        bullet.zPosition = 1//Layers the bullet on the first layer of the scene, which is above the background but below the player
        bullet.physicsBody = SKPhysicsBody(rectangleOf: bullet.size)//Physics body is the size of the bullet
        bullet.physicsBody!.affectedByGravity = false//The bullet will not be affected by gravity
        bullet.physicsBody!.categoryBitMask = PhysicsCategories.Bullet//The physics category is set to the Bullet's category
        bullet.physicsBody!.collisionBitMask = PhysicsCategories.None//The bullet should not collide with anything
        bullet.physicsBody!.contactTestBitMask = PhysicsCategories.Enemy//If the bullet makes contact with an enemy, let us know
        self.addChild(bullet)//Adds the bullet SKSpriteNode to the scene
        
        let moveBullet = SKAction.moveTo(y: self.size.height + bullet.size.height, duration: 1)//Creates a moveBullet action that will move the bullet to the end of the screen, in 1 second
        let deleteBullet = SKAction.removeFromParent()//Creates a deleteBullet action that will remove the bullet from the scene
        let bulletSequence = SKAction.sequence([moveBullet, deleteBullet])//Creates a sequence of actions for the bullet to follow, first the bullet will move to the end of the screen, then it will be removed from the scene
        bullet.run(bulletSequence)//This will execute the bullet sequence
    }
    
    func explode(spawnPosition: CGPoint) {
        let explosion = SKSpriteNode(imageNamed: "explosition")
        explosion.position = spawnPosition//The position of the explosion will be the spawn position
        explosion.zPosition = 3//The layer of the explosion is on top of all the nodes
        explosion.setScale(0)
        self.addChild(explosion)//Adds the bullet SKSpriteNode to the scene
        
        let scaleIn = SKAction.scale(to: 1, duration: 0.1)//Scale the explosion into the scene
        let fadeOut = SKAction.fadeOut(withDuration: 0.1)//Fade the explosion image
        let delete = SKAction.removeFromParent()//Remove the explosion image
        
        let explosionSequence = SKAction.sequence([scaleIn, fadeOut, delete])//Creates the sequence that the explosion will follow
        explosion.run(explosionSequence)
    }
    
    //Function to handle randomly spawning an enemy ship
    func spawnEnemy() {
        let randomXStart = random(min: gameArea.minX, max: gameArea.maxX)//Generates the random starting x of the enemy
        let randomXEnd = random(min: gameArea.minX, max: gameArea.maxX)//Generates the random ending x of the enemy
        let startPoint = CGPoint(x: randomXStart, y: self.size.height * 1.2)//Sets the startPoint to the random x start
        let endPoint = CGPoint(x: randomXEnd, y: -self.size.height * 0.2)//Sets the endPoint to the random x end
        //Creates the enemy ship, scales it, sets the position, and adds it to the scene
        let enemy = SKSpriteNode(imageNamed: "enemyShip")
        enemy.setScale(1)
        enemy.position = startPoint
        enemy.zPosition = 2//The layer of the enemy is the same as the player ship, but above the bullet
        enemy.physicsBody = SKPhysicsBody(rectangleOf: enemy.size)//Physics body is the size of the enemy ship
        enemy.physicsBody!.affectedByGravity = false//The enemy's ship will not be affected by gravity
        enemy.physicsBody!.categoryBitMask = PhysicsCategories.Enemy//The physics category is set to the Enemy's category
        enemy.physicsBody!.collisionBitMask = PhysicsCategories.None//The enemy should not collide with anything
        enemy.physicsBody!.contactTestBitMask = PhysicsCategories.Player | PhysicsCategories.Bullet//If the enemy makes contact with the Player or the Bullet, let us know
        self.addChild(enemy)
        
        let moveEnemy = SKAction.move(to: endPoint, duration: 1.5)//Creates a moveEnemy action that will move the enemy from one point to another
        let deleteEnemy = SKAction.removeFromParent()//Creates a deleteEnemy action that will remove the bullet from the scene
        let enemySequence = SKAction.sequence([moveEnemy, deleteEnemy])//Creates a sequence of actions for the enemy to follow, first the enemy will move from one point to another, then it will be removed from the scene
        enemy.run(enemySequence)//This will execute the enemy sequence
        
        //Finds the difference between the two points
        let dx = endPoint.x - startPoint.x
        let dy = endPoint.y - startPoint.y
        let rotationAmount = atan2(dy, dx)//Determines how much the rotation of the enemy ship should be
        enemy.zRotation = rotationAmount//Sets the rotation of the enemy
    }
    
    
    //Function that handles the spawning of enemy ships
    func startNewLevel() {
        level += 1
        
        //If enemies are being spawned...
        if(self.action(forKey: "spawningEnemies") != nil) {
            self.removeAction(forKey: "spawningEnemies")//Stop spawning enemies
        }
        
        var levelDuration = TimeInterval()
        //Handles the logic for each level
        switch level {
        case 1: levelDuration = 1.2
        case 2: levelDuration = 1
        case 3: levelDuration = 0.8
        case 4: levelDuration = 0.5
        default:
            levelDuration = 0.5
            print("Cannot find level info")
        }
        
        let spawn = SKAction.run(spawnEnemy)//Action that calls the spawnEnemy function
        let waitToSpawn = SKAction.wait(forDuration: levelDuration)//Spawn wait timer is set to level duration
        let spawnSequence = SKAction.sequence([waitToSpawn, spawn])//Creates a sequence of actions for the spawn system to follow
        let spawnForever = SKAction.repeatForever(spawnSequence)//Creates the action that repeats infinitely
        self.run(spawnForever, withKey: "spawningEnemies")//Keep spawning enemies
    }
    
    //Overrides the touchesBegan function, so when a user touches the screen, an action happens.
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        fireBullet()//Calls the fire bullet function
    }
    
    //Overrides the touchesMoved function, so when a user drags their finger, an action happens.
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        for touch: AnyObject in touches {
            let pointOfTouch = touch.location(in: view)//Grabs the location of the original touch
            let previousPointOfTouch = touch.previousLocation(in: view)//Grabs the previous touch location
            let amountDraggedX = pointOfTouch.x - previousPointOfTouch.x//Calculates the x distance between the initial touch and the new touch locations to find the drag distance
            let amountDraggedY = previousPointOfTouch.y - pointOfTouch.y//Calculates the y distance between the initial touch and the new touch locations to find the drag distance
            
            player.position.x += amountDraggedX//The player's new x position is updated
            player.position.y += amountDraggedY//The player's new y position is updated
            
            //If the player goes too far to the right...
            if (player.position.x > gameArea.maxX - (player.size.width / 2)){
                player.position.x = gameArea.maxX - (player.size.width / 2)//Send the player back onto the game area
            }
            //If the player goes too far to the left...
            if (player.position.x < gameArea.minX + (player.size.width / 2)){
                player.position.x = gameArea.minX + (player.size.width / 2)//Send the player back onto the game area
            }
            //If the player goes too far up...
            if (player.position.y > gameArea.maxY - (player.size.height / 2)){
                player.position.y = gameArea.maxY - (player.size.height / 2)//Send the player back onto the game area
            }
            //If the player goes too far down...
            if (player.position.y < gameArea.minY + (player.size.height / 2)){
                player.position.y = gameArea.minY + (player.size.height / 2)//Send the player back onto the game area
            }
        }
    }
    
}
