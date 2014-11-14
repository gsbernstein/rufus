# Description:
#   Github issue link looks for #nnn and links to that issue for your default
#   repo. Eg. "Hey guys check out #273"
#   Defaults to issues in HUBOT_GITHUB_REPO, unless a repo is specified Eg. "Hey guys, check out awesome-repo#273"
#
# Dependencies:
#   "githubot": "0.4.x"
#
# Configuration:
#   HUBOT_GITHUB_REPO
#   HUBOT_GITHUB_TOKEN
#   HUBOT_GITHUB_API
#   HUBOT_GITHUB_ISSUE_LINK_IGNORE_USERS
#
# Commands:
#   #nnn - link to GitHub issue nnn for HUBOT_GITHUB_REPO project
#   repo#nnn - link to GitHub issue nnn for repo project
#   user/repo#nnn - link to GitHub issue nnn for user/repo project
#
# Notes:
#   HUBOT_GITHUB_API allows you to set a custom URL path (for Github enterprise users)
#
# Derived from https://github.com/github/hubot-scripts/blob/master/src/scripts/github-issue-link.coffee

module.exports = (robot) ->
  github = require("githubot")(robot)

  githubIgnoreUsers = \
    process.env.HUBOT_GITHUB_ISSUE_LINK_IGNORE_USERS or 'github|hubot'

  robot.hear /((\S*|^)?#(\d+)).*/, (msg) ->
    return if msg.message.user.name.match new RegExp githubIgnoreUsers, 'gi'

    r = /((\S*|^)?#(\d+))/g
    while match = r.exec msg.message then do (match) ->

      issueNumber = match[3]
      return if isNaN issueNumber

      if match[2] is undefined
        repo = github.qualified_repo process.env.HUBOT_GITHUB_REPO
      else
        repo = github.qualified_repo match[2]

      baseUrl = process.env.HUBOT_GITHUB_API or 'https://api.github.com'

      github.get "#{baseUrl}/repos/#{repo}/issues/#{issueNumber}", (issue_obj) ->
        issueTitle = issue_obj.title
        url = if process.env.HUBOT_GITHUB_API
          baseUrl.replace /\/api\/v3/, ''
        else 'https://github.com'

        msg.send "*##{issueNumber}* #{issueTitle} #{url}/#{repo}/issues/#{issueNumber}"
