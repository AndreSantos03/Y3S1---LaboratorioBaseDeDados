-- Drop Old Schema
DROP SCHEMA IF EXISTS lbaw2374 CASCADE;
CREATE SCHEMA IF NOT EXISTS lbaw2374;
SET search_path TO lbaw2374;

-- Create Tables
CREATE TABLE IMAGE (
    id SERIAL PRIMARY KEY,
    path TEXT NOT NULL
);

CREATE TABLE TOPIC (
    id SERIAL PRIMARY KEY,
    title TEXT NOT NULL,
    caption TEXT NOT NULL,
    followers INTEGER CHECK (followers >= 0)
);

CREATE TABLE VIDEO (
    id SERIAL PRIMARY KEY,
    path TEXT NOT NULL
);

CREATE TABLE "user" (
    id SERIAL PRIMARY KEY,
    username TEXT UNIQUE,
    name TEXT NOT NULL,
    birthday DATE,
    country TEXT,
    gender TEXT,
    url TEXT,
    email TEXT UNIQUE,
    password TEXT,
    reputation INTEGER,
    image_id INTEGER,
    CONSTRAINT fk_userimage FOREIGN KEY(image_id) REFERENCES IMAGE(id) ON UPDATE CASCADE ON DELETE CASCADE
);

CREATE TABLE ADMIN (
    id SERIAL PRIMARY KEY,
    user_id INTEGER NOT NULL,
    CONSTRAINT fk_admin FOREIGN KEY(user_id) REFERENCES "user"(id) ON UPDATE CASCADE ON DELETE CASCADE
);

CREATE TABLE POST (
    id SERIAL PRIMARY KEY,
    title TEXT NOT NULL,
    caption TEXT NOT NULL,
    postdate timestamptz,
    upvotes INTEGER DEFAULT 0 CHECK (upvotes >= 0),
    downvotes INTEGER DEFAULT 0 CHECK (downvotes >= 0),
    user_id INTEGER NOT NULL,
    topic_id INTEGER,
    video_id INTEGER,
    CONSTRAINT fk_userpost FOREIGN KEY(user_id) REFERENCES "user"(id) ON UPDATE CASCADE ON DELETE CASCADE,
    CONSTRAINT fk_posttopic FOREIGN KEY(topic_id) REFERENCES TOPIC(id) ON UPDATE CASCADE ON DELETE CASCADE,
    CONSTRAINT fk_postvideo FOREIGN KEY(video_id) REFERENCES VIDEO(id) ON UPDATE CASCADE ON DELETE CASCADE
);

CREATE TABLE COMMENT (
    id SERIAL PRIMARY KEY,
    title TEXT NOT NULL,
    caption TEXT NOT NULL,
    commentdate timestamptz,
    upvotes INTEGER DEFAULT 0 CHECK (upvotes >= 0),
    downvotes INTEGER DEFAULT 0 CHECK (downvotes >= 0),
    post_id INTEGER NOT NULL,
    user_id INTEGER NOT NULL,
    CONSTRAINT fk_commentuser FOREIGN KEY(user_id) REFERENCES "user"(id) ON UPDATE CASCADE ON DELETE CASCADE,
    CONSTRAINT fk_postcomment FOREIGN KEY(post_id) REFERENCES POST(id) ON UPDATE CASCADE ON DELETE CASCADE
);

CREATE TABLE UPVOTE_POST(
    id SERIAL PRIMARY KEY,
    post_id INTEGER NOT NULL,
    user_id INTEGER NOT NULL,
    CONSTRAINT fk_postupvote FOREIGN KEY(post_id) REFERENCES POST(id) ON UPDATE CASCADE ON DELETE CASCADE,
    CONSTRAINT fk_userupvote FOREIGN KEY(user_id) REFERENCES "user"(id) ON UPDATE CASCADE ON DELETE CASCADE
);

CREATE TABLE DOWNVOTE_POST(
    id SERIAL PRIMARY KEY,
    post_id INTEGER NOT NULL,
    user_id INTEGER NOT NULL,
    CONSTRAINT fk_postdownvote FOREIGN KEY(post_id) REFERENCES POST(id) ON UPDATE CASCADE ON DELETE CASCADE,
    CONSTRAINT fk_userdownvote FOREIGN KEY(user_id) REFERENCES "user"(id) ON UPDATE CASCADE ON DELETE CASCADE
);

CREATE TABLE UPVOTE_COMMENT(
    id SERIAL PRIMARY KEY,
    comment_id INTEGER NOT NULL,
    user_id INTEGER NOT NULL,
    CONSTRAINT fk_commentupvote FOREIGN KEY(comment_id) REFERENCES COMMENT(id) ON UPDATE CASCADE ON DELETE CASCADE,
    CONSTRAINT fk_usercommentupvote FOREIGN KEY(user_id) REFERENCES "user"(id) ON UPDATE CASCADE ON DELETE CASCADE
);

CREATE TABLE DOWNVOTE_COMMENT(
    id SERIAL PRIMARY KEY,
    comment_id INTEGER NOT NULL,
    user_id INTEGER NOT NULL,
    CONSTRAINT fk_commentdownvote FOREIGN KEY(comment_id) REFERENCES COMMENT(id) ON UPDATE CASCADE ON DELETE CASCADE,
    CONSTRAINT fk_usercommentdownvote FOREIGN KEY(user_id) REFERENCES "user"(id) ON UPDATE CASCADE ON DELETE CASCADE
);

CREATE TABLE NOTIFICATION (
    id SERIAL PRIMARY KEY,
    user_id INTEGER NOT NULL,
    title TEXT NOT NULL,
    caption TEXT,
    type TEXT NOT NULL,
    CONSTRAINT fk_notificationuser FOREIGN KEY(user_id) REFERENCES "user"(id) ON UPDATE CASCADE ON DELETE CASCADE
);

CREATE TABLE USER_TOPIC(
    user_id INTEGER,
    topic_id INTEGER,
    PRIMARY KEY(user_id, topic_id),
    CONSTRAINT fk_usertopic FOREIGN KEY(user_id) REFERENCES "user"(id) ON UPDATE CASCADE 
    ON DELETE CASCADE,
    CONSTRAINT fk_topic FOREIGN KEY(topic_id) REFERENCES TOPIC(id) ON UPDATE CASCADE 
    ON DELETE CASCADE
);

CREATE TABLE TOPIC_PROPOSAL (
    id SERIAL PRIMARY KEY,
    user_id INTEGER NOT NULL,
    admin_id INTEGER,
    title TEXT NOT NULL,
    caption TEXT NOT NULL,
    CONSTRAINT fk_topicproposaluser FOREIGN KEY(user_id) REFERENCES "user"(id) ON UPDATE CASCADE ON DELETE CASCADE,
    CONSTRAINT fk_topicproposaladmin FOREIGN KEY (admin_id) REFERENCES ADMIN(id) ON UPDATE CASCADE ON DELETE CASCADE
);

CREATE TABLE IMAGE_POST(
    image_id INTEGER NOT NULL,
    post_id INTEGER NOT NULL,
    CONSTRAINT fk_image_post FOREIGN KEY(image_id) REFERENCES IMAGE(id) ON UPDATE CASCADE ON DELETE CASCADE,
    CONSTRAINT fk_post FOREIGN KEY(post_id) REFERENCES POST(id) ON UPDATE CASCADE ON DELETE CASCADE,
    PRIMARY KEY(image_id, post_id)
);

CREATE TABLE IMAGE_COMMENT(
    image_id INTEGER NOT NULL,
    comment_id INTEGER NOT NULL,
    CONSTRAINT fk_image_comment FOREIGN KEY(image_id) REFERENCES IMAGE(id) ON UPDATE CASCADE ON DELETE CASCADE,
    CONSTRAINT fk_comment FOREIGN KEY(comment_id) REFERENCES COMMENT(id) ON UPDATE CASCADE ON DELETE CASCADE,
    PRIMARY KEY(image_id, comment_id)
);

-- Create Indexes
CREATE INDEX post_user ON POST USING btree (user_id);
CLUSTER POST USING post_user;

CREATE INDEX comment_post ON COMMENT USING btree (post_id);
CLUSTER COMMENT USING comment_post;

CREATE INDEX notification_user ON notification USING btree (user_id);

-- Full Text Search Indexes
-- (Assuming you have a tsvector column tsvectors in POST and "user" tables)

ALTER TABLE POST
ADD COLUMN tsvectors TSVECTOR;

-- Create function for updating POST search index
CREATE OR REPLACE FUNCTION post_search_update()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'INSERT' THEN
        NEW.tsvectors = (
         setweight(to_tsvector('english', NEW.title), 'A') ||
         setweight(to_tsvector('english', NEW.caption), 'B')
        );
 END IF;
 IF TG_OP = 'UPDATE' THEN
         IF (NEW.title <> OLD.title OR NEW.caption <> OLD.caption) THEN
           NEW.tsvectors = (
             setweight(to_tsvector('english', NEW.title), 'A') ||
             setweight(to_tsvector('english', NEW.caption), 'B')
           );
         END IF;
 END IF;
 RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger for updating POST search index
CREATE TRIGGER post_search_update_trigger
BEFORE INSERT OR UPDATE ON POST
FOR EACH ROW
EXECUTE FUNCTION post_search_update();

-- Create the GIN index for POST full-text search
ALTER TABLE "user"
ADD COLUMN tsvectors TSVECTOR;

-- Create function for updating "user" search index
CREATE OR REPLACE FUNCTION user_search_update()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'INSERT' THEN
        NEW.tsvectors = (
         setweight(to_tsvector('english', NEW.name), 'A') ||
         setweight(to_tsvector('english', NEW.username), 'B')
        );
 END IF;
 IF TG_OP = 'UPDATE' THEN
         IF (NEW.name <> OLD.name OR NEW.username <> OLD.username) THEN
           NEW.tsvectors = (
             setweight(to_tsvector('english', NEW.name), 'A') ||
             setweight(to_tsvector('english', NEW.username), 'B')
           );
         END IF;
 END IF;
 RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger for updating post upvotes count
CREATE OR REPLACE FUNCTION update_post_votes_count()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'INSERT' THEN
        UPDATE post
        SET upvotes = upvotes + 1
        WHERE id = NEW.post_id;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_post_trigger
AFTER INSERT ON upvote_post
FOR EACH ROW
EXECUTE FUNCTION update_post_votes_count();

-- Trigger for updating post upvotes and downvotes count
CREATE OR REPLACE FUNCTION downvote_post_votes_count()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'INSERT' THEN
        UPDATE post
        SET downvotes = downvotes + 1
        WHERE id = NEW.post_id;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER downvote_post_trigger
AFTER INSERT ON downvote_post
FOR EACH ROW
EXECUTE FUNCTION downvote_post_votes_count();

-- Trigger for updating comment upvotes count
CREATE OR REPLACE FUNCTION update_comment_votes_count()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'INSERT' THEN
        UPDATE comment
        SET upvotes = upvotes + 1
        WHERE id = NEW.comment_id;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_comment_trigger
AFTER INSERT ON upvote_comment
FOR EACH ROW
EXECUTE FUNCTION update_comment_votes_count();

-- Trigger for updating comment downvotes count
CREATE OR REPLACE FUNCTION downvote_comment_votes_count()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'INSERT' THEN
        UPDATE comment
        SET downvotes = downvotes + 1
        WHERE id = NEW.comment_id;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER downvote_comment_trigger
AFTER INSERT ON downvote_comment
FOR EACH ROW
EXECUTE FUNCTION downvote_comment_votes_count();

-- Trigger for updating "user" search index
CREATE TRIGGER user_search_update_trigger
BEFORE INSERT OR UPDATE ON "user"
FOR EACH ROW
EXECUTE FUNCTION user_search_update();

-- Trigger for creating notification when a "user" comments on a POST
CREATE OR REPLACE FUNCTION new_comment_notification()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO notification (user_id, title, type)
    VALUES ((SELECT user_id FROM POST WHERE id = NEW.post_id), 'New COMMENT on your POST', 'New COMMENT');
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger for enforcing COMMENT date constraint
CREATE OR REPLACE FUNCTION enforce_comment_date_constraint()
RETURNS TRIGGER AS $$
BEGIN
 
  IF NEW.commentdate < (SELECT POST.postdate FROM POST WHERE POST.id = NEW.post_id) THEN
    RAISE EXCEPTION 'COMMENT date must be greater than or equal to the news publication date';
  END IF;

  RETURN NEW;
END
$$ LANGUAGE plpgsql;

-- Attach triggers to the COMMENT table
CREATE TRIGGER new_comment_trigger
AFTER INSERT ON COMMENT
FOR EACH ROW
EXECUTE FUNCTION new_comment_notification();

CREATE TRIGGER enforce_comment_date_constraint_trigger
BEFORE INSERT ON COMMENT
FOR EACH ROW
EXECUTE FUNCTION enforce_comment_date_constraint();

--Create Trigger for POST UPVOTE/DOWNVOTE counter

--Create Trigger for COMMENT UPVOTE/DOWNVOTE counter

--  Insert new POST
/*BEGIN;
SET TRANSACTION ISOLATION LEVEL REPEATABLE READ;
INSERT INTO POST (title, caption, postdate, upvotes, downvotes, user_id, topic_id)
VALUES (%title,%caption,%postdate, 0, 0, %user_id, %topic_id);
INSERT INTO image (post_id, path)
VALUES (currval('post_id_seq'), %path);
COMMIT;

-- Retrieve latest comments from active "user"
BEGIN;
SET TRANSACTION ISOLATION LEVEL SERIALIZABLE READ ONLY;
WITH LatestComments AS (
    SELECT user_id, MAX(commentdate) AS latest_comment_date
    FROM COMMENT
    GROUP BY user_id
    HAVING MAX(commentdate) >= CURRENT_DATE - INTERVAL '3 months'
)
SELECT "user".id AS user_id, "user".name AS user_name, 
       COMMENT.id AS comment_id, COMMENT.title AS comment_title, 
       COMMENT.caption AS comment_caption, COMMENT.commentdate
FROM "user"
JOIN COMMENT ON "user".id = COMMENT.user_id
JOIN LatestComments ON COMMENT.user_id = LatestComments.user_id
WHERE COMMENT.commentdate = LatestComments.latest_comment_date
ORDER BY "user".id, COMMENT.id;
COMMIT;*/

-- Create "user" table and populate data
INSERT INTO "user" (id, name, username, birthday, country, gender, url, email, password, reputation)
VALUES (1, 'John Doe', 'johndoe', '1990-05-15', 'USA', 'Male', 'http://example.com', 'johndoe@example.com', 'password123', 100),
       (2, 'Alice Johnson', 'alicej', '1988-03-10', 'Toronto', 'Female',  'http://example.com/alice', 'alice@example.com', 'pass123', 120),
       (3, 'Bob Anderson', 'bob123', '1995-11-28', 'USA', 'Male', 'http://example.com/bob', 'bob@example.com', 'securepass', 90),
       (4, 'Eva Brown', 'evab', '1982-07-15', 'UK', 'Female', 'http://example.com/eva', 'eva@example.com', 'eva123', 80),
       (5, 'Jane Smith', 'janesmith', '1985-08-20', 'USA', 'Female', 'http://example.com/jane', 'janesmith@example.com', 'securepass', 150),
       (6, 'Michael Adams', 'mike123', '1980-09-05', 'USA', 'Male', 'http://example.com/mike', 'mike@example.com', 'mikepass', 110),
       (7, 'Sophie Martinez', 'sophie89', '1992-02-18', 'Spain', 'Female', 'http://example.com/sophie', 'sophie@example.com', 'sophie123', 95),
       (8, 'David Lee', 'davidl', '1986-07-30', 'Canada', 'Male',  'http://example.com/david', 'david@example.com', 'davidpass', 85),
       (9, 'Emma White', 'emmaw', '1998-12-12', 'Australia', 'Female', 'http://example.com/emma', 'emma@example.com', 'emma456', 75),
       (10, 'Olivia Taylor', 'olivia88', '1984-06-14', 'USA', 'Female', 'http://example.com/olivia', 'olivia@example.com', 'olivia567', 130),
       (11, 'Liam Brown', 'liamb', '1991-09-22', 'UK', 'Male', 'http://example.com/liam', 'liam@example.com', 'liampass', 105),
       (12, 'Ava Clark', 'ava.c', '1989-03-30', 'Canada', 'Female', 'http://example.com/ava', 'ava@example.com', 'ava321', 95),
       (13, 'Noah Evans', 'noah.e', '1995-12-05', 'Australia', 'Male', 'http://example.com/noah', 'noah@example.com', 'noahpass', 85);

-- Create ADMIN table and populate data
INSERT INTO ADMIN (user_id)
VALUES (1),
       (3),
       (6),
       (11);

-- Create topic table and populate data
INSERT INTO TOPIC (title, caption, followers)
VALUES ('Technology', 'Discussions about the latest tech trends', 500),
       ('Travel', 'Explore the world and share your experiences', 300),
       ('Science', 'Discussion about scientific discoveries', 200),
       ('Food', 'Delicious recipes and culinary adventures', 400),
       ('Music', 'Explore the world of music and artists', 300),
       ('Art', 'Appreciating and creating art in all forms', 150),
       ('Fitness', 'Tips, tricks, and motivation for staying fit', 250),
       ('Books', 'Discussing favorite books and literary works', 180),
       ('Fashion', 'Trends, styles, and fashion tips', 180),
       ('Gaming', 'Video games, reviews, and gaming culture', 280),
       ('Health', 'Wellness, fitness, and healthy living', 200);

-- Create post table and populate data
INSERT INTO POST (title, caption, postdate, upvotes, downvotes, user_id, topic_id)
VALUES ('Introduction to AI', 'A beginners guide to Artificial Intelligence', '2023-10-20', 50, 5, 1, 1),
       ('Best Travel Destinations', 'Must-visit places around the globe', '2023-10-21', 30, 2, 2, 2),
       ('The Future of Space Exploration', 'Exciting developments in space science', '2023-10-22', 70, 3, 1, 1),
       ('Classic Italian Pasta Recipes', 'Mouth-watering pasta recipes from Italy', '2023-10-23', 40, 1, 3, 2),
       ('Top 10 Rock Albums of All Time', 'A journey through iconic rock music', '2023-10-24', 60, 2, 2, 3),
       ('Modern Abstract Art', 'Exploring the world of abstract art', '2023-10-25', 35, 2, 1, 1),
       ('Effective Cardio Workouts', 'Maximize your cardio sessions', '2023-10-26', 45, 3, 2, 2),
       ('Classic Novels You Must Read', 'Timeless literary classics', '2023-10-27', 55, 1, 3, 3),
       ('Australian Wildlife Photography', 'Capturing unique wildlife in Australia', '2023-10-28', 40, 1, 4, 1),
       ('Latest Fashion Trends', 'Stay in style with these trends', '2023-10-29', 42, 2, 1, 1),
       ('Top RPG Games of All Time', 'Explore the best role-playing games', '2023-10-30', 63, 1, 2, 2),
       ('Healthy Eating Habits', 'Tips for a balanced and nutritious diet', '2023-10-31', 55, 3, 3, 3),
       ('Australian Beaches Guide', 'Discover the most beautiful beaches', '2023-11-01', 48, 2, 4, 1);


-- Create comment table and populate data
INSERT INTO COMMENT (title, caption, commentdate, upvotes, downvotes, post_id, user_id)
VALUES ('Great article!', 'Very informative, thanks for sharing.', '2023-10-20', 20, 0, 1, 2),
       ('I completely agree', 'These destinations are amazing!', '2023-10-21', 15, 1, 2, 1),
       ('Amazing!', 'Im fascinated by space exploration.', '2023-10-22', 25, 1, 1, 3),
       ('Delicious!', 'I tried one of the recipes, and it was fantastic!', '2023-10-23', 20, 0, 2, 1),
       ('Rock on!', 'Great list! I love classic rock albums.', '2023-10-24', 30, 1, 3, 2),
       ('Inspiring!', 'Abstract art always sparks creativity.', '2023-10-25', 18, 1, 1, 2),
       ('Great tips!', 'I tried these workouts, and they work wonders!', '2023-10-26', 22, 0, 2, 3),
       ('Love these classics!', 'Pride and Prejudice is my favorite.', '2023-10-27', 25, 1, 3, 1),
       ('Amazing photos!', 'The wildlife in Australia is truly unique.', '2023-10-28', 20, 0, 4, 2),
       ('Love these outfits!', 'Fashion inspiration at its best.', '2023-10-29', 30, 1, 1, 3),
       ('Great list!', 'Ive played most of these games, they are fantastic.', '2023-10-30', 40, 0, 2, 4),
       ('Important tips!', 'Healthy eating is crucial for a good life.', '2023-10-31', 35, 2, 3, 2),
       ('Fantastic guide!', 'Planning my next beach vacation already.', '2023-11-01', 25, 0, 4, 3);


-- Create notification table and populate data
INSERT INTO NOTIFICATION (user_id, title, caption, type)
VALUES (1, 'New Follower', 'User xyz started following you.', 'follower'),
       (2, 'New Comment', 'Your post received a new comment.', 'comment'),
       (3, 'New Follower', 'User xyz started following you.', 'follower'),
       (1, 'New Comment', 'Your post received a new comment.', 'comment'),
       (4, 'New Follower', 'User abc started following you.', 'follower'),
       (1, 'New Comment', 'Your post received a new comment.', 'comment'),
       (2, 'New Follower', 'User xyz started following you.', 'follower'),
       (3, 'New Comment', 'Your post received a new comment.', 'comment');


-- Create topic_proposal table and populate data
INSERT INTO TOPIC_PROPOSAL (user_id, admin_id, title, caption)
VALUES (2, 1, 'Foodie Adventures', 'Exploring different cuisines and food cultures'),
       (1, 2, 'Wildlife Photography', 'Capturing the beauty of nature through photography'),
       (4, 3, 'Healthy Cooking', 'Delicious and nutritious recipes for a healthy lifestyle'),
       (1, 4, 'Home Decor Ideas', 'Creative and budget-friendly home decoration tips');


