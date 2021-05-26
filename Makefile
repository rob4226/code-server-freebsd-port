PORTNAME=	code-server
DISTVERSION=	3.10.2
CATEGORIES=	www
MASTER_SITES= https://registry.npmjs.org/code-server/-/

MAINTAINER=	FreeBSD@appkingsoftware.com
COMMENT=	Run VS Code on any machine anywhere and access it in the browser

LICENSE=	MIT
LICENSE_FILE=	${WRKSRC}/LICENSE.txt

BUILD_DEPENDS=  npm-node14>0:www/npm-node14 \
 				yarn-node14>0:www/yarn-node14 \
 				pkgconf>0:devel/pkgconf \
 				libsecret>0:security/libsecret \
 				libxkbfile>0:x11/libxkbfile \
 				libX11>0:x11/libX11 \
 				libinotify>0:devel/libinotify
LIB_DEPENDS= 	libinotify.so:devel/libinotify
RUN_DEPENDS=	npm-node14>0:www/npm-node14

USES= 		tar:tgz shebangfix python:3.0+
USE_RC_SUBR=	${PORTNAME}

WRKSRC=		${WRKDIR}/package

SHEBANG_FILES=	lib/vscode/extensions/ms-vscode.node-debug/dist/terminateProcess.sh \
				lib/vscode/extensions/ms-vscode.js-debug/src/terminateProcess.sh \
				lib/vscode/extensions/ms-vscode.node-debug2/out/src/terminateProcess.sh \
				lib/vscode/extensions/ms-vscode.node-debug2/src/terminateProcess.sh

do-build:
	cd ${WRKSRC} && ${SETENV} ${MAKE_ENV} npm i --production --unsafe-perm

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
