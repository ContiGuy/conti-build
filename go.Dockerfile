# small but not based on debian/ubuntu, so no apt packages available
# FROM golang:alpine
# FROM golang:wheezy
FROM golang

ARG UserID
ARG GroupID
ARG OdenVersion

#
# setup Elm environment
#

# install npm
#RUN curl -sL https://deb.nodesource.com/setup_6.x | bash -
#RUN apt-get update
#RUN apt-get install -y nodejs

# install elm
#RUN npm install -g elm

# # install purescript and it's tools
# RUN npm install -g purescript pulp bower


# open port for elm reactor
##EXPOSE 8000

# ENTRYPOINT [ "elm" ]

#
# setup Go environment
#

WORKDIR /go/src

# # add a helper tool written in Go
# ADD gopath gopath
# RUN go install gopath
# RUN GOOS=windows GOARCH=amd64 go install gopath

# create a non root developer user with the same user id as the developer who builds the docker image so that later the built files can be owned by him
RUN addgroup --gid "${GroupID}" developer
#~alpine: RUN addgroup -g "${GroupID}" developer

# FIXME: need to prevent interactive output
RUN adduser --uid "${UserID}" --gid "${GroupID}" --no-create-home --disabled-password --gecos "the local Go developer" developer
#~alpine: RUN adduser -u "${UserID}" -G developer -D developer

# add a helper tool written in Go
ADD cobui cobui
RUN go install --race cobui
#~alpine: RUN go install cobui
##RUN GOOS=windows GOARCH=amd64 go install cobui

# ensure that the developer can actually create libraries and binaries
RUN chown -R developer:developer /go
RUN chown -R developer:developer /usr/local/go

# open port for go doc
##EXPOSE 6060

#
# setup Go environment
#

WORKDIR /go/src

# # add a helper tool written in Go
# ADD gopath gopath
# RUN go install gopath
# RUN GOOS=windows GOARCH=amd64 go install gopath

# # add a vendoring tool written in Go
# RUN go get github.com/FiloSottile/gvt
# RUN go install github.com/FiloSottile/gvt
# 
# # add a vendoring tool written in Go
# RUN go get github.com/spf13/cobra
# RUN go install github.com/FiloSottile/gvt

# add a some tools written in Go
RUN for pkg in                         \
	github.com/FiloSottile/gvt         \
	github.com/spf13/cobra             \
	github.com/spf13/cobra/cobra       \
	github.com/benbjohnson/ego         \
	github.com/benbjohnson/ego/cmd/ego \
	github.com/alecthomas/gometalinter \
; do                                   \
    go get "$pkg" &&                   \
      go install "$pkg";               \
done

RUN cd /go/bin && cp $(ls | grep -v _) /usr/local/go/bin

RUN gometalinter --install --update

# install Oden

# RUN apt-get update
# RUN apt-get install -y libpcre3-dev

RUN mkdir -p /source
WORKDIR /source
# RUN git clone https://github.com/oden-lang/oden.git
RUN wget "https://github.com/oden-lang/oden/releases/download/${OdenVersion}/oden-${OdenVersion}-linux.tar.gz" && tar xvzf "oden-${OdenVersion}-linux.tar.gz"
WORKDIR /source/oden
RUN mkdir -p /usr/local/go/bin  /usr/local/go/lib  /usr/local/go/doc
RUN cp bin/* /usr/local/go/bin
RUN cp -R doc/* /usr/local/go/doc
RUN cp -R lib/* /usr/local/go/lib

# RUN ls -laR /usr/local/go/bin  /usr/local/go/lib


# RUN find github.com/spf13/cobra -type d


# add some more useful tools
RUN apt-get update
RUN apt-get install -y upx zip

