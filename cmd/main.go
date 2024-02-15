package main

import (
    "archive/zip"
    "fmt"
    "io"
    "os"
    "os/signal"
    "path/filepath"
    "strings"
    "syscall"
    
    "github.com/bwmarrin/discordgo"
    "github.com/joho/godotenv"
    "github.com/robfig/cron/v3"
)

func main() {
    // load .env file
    err := godotenv.Load()
    if err != nil {
        fmt.Println("Error loading .env file")
        return
    }

    // get token from env
    botToken := os.Getenv("DISCORD_BOT_TOKEN")
    if botToken == "" {
        fmt.Println("No bot token found in environment.")
        return
    }

    // create new discord session
    dg, err := discordgo.New("Bot " + botToken)
    if err != nil {
        fmt.Println("Error creating discord session", err)
        return
    }

    // set file path and channel id
    sourceDir := "../output"
    targetZip := "./data.zip"
    channelID := os.Getenv("DISCORD_CHANNEL_ID")
    if channelID == "" {
        fmt.Println("No channel ID found in environment.")
        return
    }

    // create cron job and schedule
    c := cron.New()
    // _, err = c.AddFunc("*/1 * * * *", func() { // every 1 minute
    _, err = c.AddFunc("0 8-20 * * 6,7", func() { // 8am-8pm sat, sun
        zipToDiscord(dg, channelID, sourceDir, targetZip)
    })

    // start cron scheduler
    c.Start()

    // register handlers and open connection to discord via websocket
    dg.AddHandler(messageCreate)
    err = dg.Open()
    if err != nil {
        fmt.Println("Error opening connection.", err)
        return
    }
    fmt.Println("Bot is now running. Press ctrl+c to exit.")


    // wait until term signal is received
    sc := make(chan os.Signal, 1)
    signal.Notify(sc, syscall.SIGINT, syscall.SIGTERM, os.Interrupt, os.Kill)
    <-sc

    // stop cron scheduler
    c.Stop()

    // close discord session
    dg.Close()
}


// discord message creation handler
func messageCreate(s *discordgo.Session, m *discordgo.MessageCreate) {
    if m.Author.ID == s.State.User.ID {
        return
    }

    // get channel id from env
    channelID := os.Getenv("DISCORD_CHANNEL_ID")

    // TODO: adapt to target specific events
    // check if message was sent in valid channel and if correct prefix was used
    if m.ChannelID == channelID && strings.HasPrefix(m.Content, ":EventsGet") {
        // slice message from first space to end (extract event key)
        i := strings.Index(m.Content, " ")
        if i == -1 { 
            s.ChannelMessageSend(m.ChannelID, 
                "Provide a valid event key (i.e. '2023vagle') or 'all' to get event statistics.")
            return 
        }
        eventkey := m.Content[i:]

        // check if event key matches
        if eventkey == "all" {
            s.ChannelMessageSend(m.ChannelID, "Getting data for all processed events")
            zipToDiscord(s, channelID, "../output", "./data.zip")
            return
        }
        // TODO: check other events
        // TODO: list valid events "list" command probably
    }

    if m.Content == ":ping" {
        s.ChannelMessageSend(m.ChannelID, "pong") 
        return
    }
}


// zip source dir, send to discord in specified channel
func zipToDiscord(s *discordgo.Session, channelID, sourceDir string, targetZipPath string) {
    fmt.Println("Running Job...")
    err := zipDir(sourceDir, targetZipPath)
    if err != nil {
        fmt.Println("Error zipping folder:", err)
        return
    }

    // upload
    err = uploadToDiscord(s, channelID, targetZipPath)
    if err != nil {
        fmt.Println("Error uploading the file to Discord:", err)
        return
    }
    fmt.Println("File uploaded successfully.")

    // delete zip after sending
    err = os.Remove(targetZipPath)
    if err != nil {
        fmt.Println("Error deleting zip file:", err)
    } else {
        fmt.Println("Zip file deleted successfully")
    }
}


// helper function that uploads a file to discord to a specific channel
func uploadToDiscord(s *discordgo.Session, channelID, filePath string) error {
    file, err := os.Open(filePath)
    if err != nil {
        return err
    }
    defer file.Close()

    // get files stats
    stats, err := file.Stat()
    if err != nil {
        return err
    }

    // TODO: send accompanying message w/time, maybe event names updated?
    // - event names would be nice, would require reworking R output structure
    message := &discordgo.MessageSend{
        Files: []*discordgo.File{
            {
                Name:   stats.Name(),
                Reader: file,
            },
        },
    }
    
    // send message with attached file
    _, err = s.ChannelMessageSendComplex(channelID, message)
    return err
}


// create zip file from directory
func zipDir(source, target string) error {
    // TODO: specified command could target specific event key
    // TODO: update to step through output dir and zip (new?/updated?) dirs for events
    // TODO: needs way of dealing with larger zip files (send one for each event?)

    // delete zip if it already exists
    if _, err := os.Stat(target); err == nil {
        err := os.Remove(target)
        if err != nil {
            fmt.Println("Error deleting zip file:", err)
            return err
        } else {
            fmt.Println("Existing zip file deleted successfully.")
        }
    } else if !os.IsNotExist(err) {
        fmt.Println("Error checking for existing zip file:", err)
        return err
    }

    zipfile, err := os.Create(target)
    if err != nil {
        return err
    }

    defer zipfile.Close() 

    archive := zip.NewWriter(zipfile)
    defer archive.Close()

    // walk through all files/dirs in source dir
    filepath.Walk(source, func(path string, info os.FileInfo, err error) error {
        if err != nil {
            return err
        }

        // disallow zip and png files from being included in the new zip
        if filepath.Ext(path) == ".zip" || filepath.Ext(path) == ".png" {
            return nil
        }

        header, err := zip.FileInfoHeader(info)
        if err != nil {
            return err
        }

        header.Name = filepath.ToSlash(path[len(source):])
        if info.IsDir() {
            header.Name += "/"
        } else {
            header.Method = zip.Deflate
        }

        writer, err := archive.CreateHeader(header)
        if err != nil {
            return err
        }

        if !info.IsDir() {
            file, err := os.Open(path)
            if err != nil {
                return err
            }
            defer file.Close()
            _, err = io.Copy(writer, file)
        }

        return err
    })

    return nil
}
