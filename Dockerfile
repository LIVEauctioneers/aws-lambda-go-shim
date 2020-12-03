#
# Copyright 2017 Alsanium, SAS. or its affiliates. All rights reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

FROM amazonlinux:2017.09.0.20170930 as builder

ENV GOLANG_VERSION 1.15.5
ENV GOLANG_DOWNLOAD_URL https://golang.org/dl/go$GOLANG_VERSION.linux-amd64.tar.gz
ENV GOLANG_DOWNLOAD_SHA256 9a58494e8da722c3aef248c9227b0e9c528c7318309827780f16220998180a0d

RUN true\
  && yum -e 0 -y install gcc python27-devel || true\
  && yum -e 0 -y clean all

RUN true\
  && curl -fSL "$GOLANG_DOWNLOAD_URL" -o golang.tar.gz\
  && echo "$GOLANG_DOWNLOAD_SHA256 golang.tar.gz" | sha256sum -c -\
  && tar -C /usr/local -xzf golang.tar.gz; rm golang.tar.gz

ADD src src

RUN true\
  && mkdir dist\
  && /usr/local/go/bin/go build\
        -buildmode=c-shared\
        -ldflags='-w -s'\
        -o dist/runtime.so ./src\
  && python -m compileall -d runtime src

RUN true\
  && cp src/*.pyc dist/.\
  && cp src/pack.bash dist/pack\
  && cp src/version.bash dist/version

RUN sed -i "s/VERSION/$(date -u +%Y-%m-%dT%H:%M:%SZ)/g" dist/version

FROM amazonlinux:2017.09.0.20170930

ENV PATH /usr/local/go/bin:/shim:$PATH

RUN true\
  && yum -e 0 -y install gcc zip findutils || true\
  && yum -e 0 -y clean all

COPY --from=builder /usr/local/go /usr/local/go
COPY --from=builder dist /shim
