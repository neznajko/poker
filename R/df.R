prognom <- c("../C/poker -m", "../poker")
nxp <- 100 # number of experiments
gamez <- as.integer(10^(2:5)) # number of games
tbl <- '"AcKc JsTc QhQc -- 2s----"'
res <- NULL
lang <- c("C", "nasm")
#
for (i in (1:2)) {
    for (g in gamez) {
        cmd <- paste(prognom[i], g, tbl, "> /dev/null", sep = " ")
        print(cmd)
        for (j in (1:nxp)) {
            t <- system.time(system(cmd))
            print(t)
            res <- append(res, t[1] + t[4])
        }
    }
}
time <- data.frame(time = res,
                   lang = factor(rep(lang, each = nxp*length(gamez))),
                   gmez = factor(rep(gamez, each = nxp)))
# 
save(time, file = "time.df")
