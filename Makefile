PORTNAME=	code-server
DISTVERSION=	3.10.2
CATEGORIES=	www
MASTER_SITES=	https://registry.npmjs.org/code-server/-/:codeserver \
		http://mikael.urankar.free.fr/code-server/:npm_cache \
		http://mikael.urankar.free.fr/code-server/:yarn_cache \
		https://nodejs.org/dist/v${NODE_VER}/:node_headers
DISTFILES=	${PORTNAME}-${DISTVERSION}.tgz:codeserver \
		${PORTNAME}-npm-modules-${DISTVERSION}${EXTRACT_SUFX}:npm_cache \
		${PORTNAME}-yarn-modules-${DISTVERSION}${EXTRACT_SUFX}:yarn_cache \
		node-v${NODE_VER}-headers.tar.gz:node_headers

MAINTAINER=	FreeBSD@appkingsoftware.com
COMMENT=	Run VS Code on any machine anywhere and access it in the browser

LICENSE=	MIT
LICENSE_FILE=	${WRKSRC}/LICENSE.txt

BUILD_DEPENDS=	npm-node${NODE_VER_MAJOR}>0:www/npm-node${NODE_VER_MAJOR} \
		yarn-node${NODE_VER_MAJOR}>0:www/yarn-node${NODE_VER_MAJOR} \
 		pkgconf>0:devel/pkgconf \
 		libsecret>0:security/libsecret \
 		libxkbfile>0:x11/libxkbfile \
 		libX11>0:x11/libX11 \
 		libinotify>0:devel/libinotify
LIB_DEPENDS=	libinotify.so:devel/libinotify
RUN_DEPENDS=	npm-node${NODE_VER_MAJOR}>0:www/npm-node${NODE_VER_MAJOR}

USES=		tar:tgz shebangfix python:3.6+
USE_RC_SUBR=	${PORTNAME}

WRKSRC=		${WRKDIR}/package

SHEBANG_FILES=	lib/vscode/extensions/ms-vscode.node-debug/dist/terminateProcess.sh \
		lib/vscode/extensions/ms-vscode.js-debug/src/terminateProcess.sh \
		lib/vscode/extensions/ms-vscode.node-debug2/out/src/terminateProcess.sh \
		lib/vscode/extensions/ms-vscode.node-debug2/src/terminateProcess.sh

# Taken from https://github.com/tagattie/FreeBSD-Electron
NODE_VER=		14.17.0
NODE_VER_MAJOR=		${NODE_VER:C/\..*$//}
PREFETCH_TIMESTAMP=	1616313125 # epoch ??? Sunday, 21 March 2021
PKGJSONSDIR=		${FILESDIR}/packagejsons
YARN_CMD=		${LOCALBASE}/bin/${_YARN_BASE_CMD}
_YARN_BASE_CMD=		yarn

# Helper targets for port maintainers
# xxx move this in pre-fetch?
make-npm-cache:
	# do "make configure" before executing this target
	cd ${WRKDIR} && ${RM} -r .npm
	cd ${WRKSRC} && \
		${SETENV} HOME=${WRKDIR} npm install --ignore-scripts
	cd ${WRKDIR}/.npm && \
		${RM} -r _locks anonymous-cli-metrics.json
	cd ${WRKDIR} && \
		${TAR} -czf npm-cache-${PORTNAME}-${DISTVERSION}${EXTRACT_SUFX} .npm

# to create the yarn.lock, basically:
# for i in lib/vscode lib/vscode/extensions lib/vscode/extensions/notebook-markdown-extensions lib/vscode/extensions/npm
# do
#    cd ${WRKSRC}/$i
#    yarn --ignore-script --production
#    cp package.json yarn.lock ${FILESDIR}/packagejsons/${i}
# done
#
pre-fetch:
	@if [ ! -f ${DISTDIR}/${PORTNAME}-yarn-modules-${DISTVERSION}${EXTRACT_SUFX} ]; then \
		${ECHO_MSG} "===>  Distfile ${DISTDIR}/${PORTNAME}-yarn-modules-${DISTVERSION}${EXTRACT_SUFX} not found"; \
		${ECHO_MSG} "===>  Pre-fetching and archiving node modules"; \
		${MKDIR} ${WRKDIR}; \
		${ECHO_CMD} 'yarn-offline-mirror "./yarn-offline-cache"' >> \
			${WRKDIR}/.yarnrc; \
		${CP} -r ${PKGJSONSDIR}/* ${WRKDIR}; \
		cd ${PKGJSONSDIR} && \
		for dir in `${FIND} . -type f -name package.json -exec dirname {} ';'`; do \
			cd ${WRKDIR}/$${dir} && \
			${SETENV} HOME=${WRKDIR} XDG_CACHE_HOME=${WRKDIR}/.cache \
				${YARN_CMD} --frozen-lockfile --ignore-scripts --production && \
			${RM} package.json yarn.lock; \
		done; \
		cd ${WRKDIR}; \
		${MTREE_CMD} -cbnSp yarn-offline-cache | ${MTREE_CMD} -C | ${SED} \
			-e 's:time=[0-9.]*:time=${PREFETCH_TIMESTAMP}.000000000:' \
			-e 's:\([gu]id\)=[0-9]*:\1=0:g' \
			-e 's:flags=.*:flags=none:' \
			-e 's:^\.:./yarn-offline-cache:' > yarn-offline-cache.mtree; \
		${TAR} -cz --options 'gzip:!timestamp' \
			-f ${DISTDIR}/${PORTNAME}-yarn-modules-${DISTVERSION}${EXTRACT_SUFX} @yarn-offline-cache.mtree; \
	fi

pre-build:
	@${ECHO_MSG} "===>  Copying package.json and yarn.lock to WRKSRC"
	@cd ${PKGJSONSDIR} && \
	for dir in `${FIND} . -type f -name package.json -exec dirname {} ';'`; do \
		for f in package.json yarn.lock; do \
			if [ -f ${WRKSRC}/$${dir}/$${f} ]; then \
				${MV} -f ${WRKSRC}/$${dir}/$${f} ${WRKSRC}/$${dir}/$${f}.bak; \
			fi; \
			${CP} -f $${dir}/$${f} ${WRKSRC}/$${dir}; \
		done; \
	done
	@${ECHO_MSG} "===>  Installing node modules from pre-fetched cache"
	@${ECHO_CMD} 'yarn-offline-mirror "../yarn-offline-cache"' >> ${WRKSRC}/.yarnrc
	@${ECHO_CMD} 'nodedir "${WRKDIR}/node-v${NODE_VER}"' >> ${WRKSRC}/.yarnrc
	@cd ${PKGJSONSDIR} && \
	for dir in lib/vscode lib/vscode/extensions lib/vscode/extensions/notebook-markdown-extensions lib/vscode/extensions/npm; do \
		cd ${WRKSRC}/$${dir} && ${SETENV} HOME=${WRKDIR} XDG_CACHE_HOME=${WRKDIR}/.cache \
			${YARN_CMD} --production --frozen-lockfile --offline; \
	done

do-build:
	cd ${WRKSRC} && ${SETENV} ${MAKE_ENV} \
		npm install --production --unsafe-perm

pre-install:
	${RM} ${WRKSRC}/node_modules/pem/bin/test_build_openssl.sh
	${RM} ${WRKSRC}/lib/vscode/node_modules/vscode-sqlite3/Dockerfile
	${RM} ${WRKSRC}/lib/vscode/node_modules/vscode-sqlite3/tools/docker/architecture/linux-arm64/Dockerfile
	${RM} ${WRKSRC}/lib/vscode/node_modules/spdlog/deps/spdlog/format.sh
	${RM} ${WRKSRC}/lib/vscode/node_modules/spdlog/deps/spdlog/tests/install_libcxx.sh
	${RM} ${WRKSRC}/lib/vscode/node_modules/spdlog/deps/spdlog/bench/latency/compare.sh
	${STRIP_CMD} ${WRKSRC}/lib/vscode/node_modules/nsfw/build/Release/nsfw.node
	${STRIP_CMD} ${WRKSRC}/lib/vscode/node_modules/nsfw/build/Release/obj.target/nsfw.node
	${STRIP_CMD} ${WRKSRC}/lib/vscode/node_modules/node-pty/build/Release/pty.node
	${STRIP_CMD} ${WRKSRC}/lib/vscode/node_modules/vscode-sqlite3/build/Release/obj.target/sqlite.node
	${STRIP_CMD} ${WRKSRC}/lib/vscode/node_modules/vscode-sqlite3/build/Release/sqlite.node
	${STRIP_CMD} ${WRKSRC}/lib/vscode/node_modules/native-is-elevated/build/Release/obj.target/iselevated.node
	${STRIP_CMD} ${WRKSRC}/lib/vscode/node_modules/native-is-elevated/build/Release/iselevated.node
	${STRIP_CMD} ${WRKSRC}/lib/vscode/node_modules/spdlog/build/Release/obj.target/spdlog.node
	${STRIP_CMD} ${WRKSRC}/lib/vscode/node_modules/spdlog/build/Release/spdlog.node
	${STRIP_CMD} ${WRKSRC}/lib/vscode/node_modules/native-watchdog/build/Release/obj.target/watchdog.node
	${STRIP_CMD} ${WRKSRC}/lib/vscode/node_modules/native-watchdog/build/Release/watchdog.node

do-install:
	${MKDIR} ${STAGEDIR}${DATADIR}
	${CP} -R ${WRKSRC}/* ${STAGEDIR}${DATADIR}
	${RLN} ${STAGEDIR}${DATADIR}/out/node/entry.js ${STAGEDIR}${PREFIX}/bin/${PORTNAME}

.include <bsd.port.mk>
