_SCHEME='FMDB-IOS'

#---- variables to store build parameters
_SDK=""            # e.g. 'iphonesimulator'
_CONFIGURATION=""  # e.g. 'Release'
_RET=""

Xcode_build()
{
	printf "[i] xcodebuild -project \"${PRODUCT_NAME}.xcodeproj\" -scheme \"${_SCHEME}\" -sdk \"${_SDK}\" -configuration \"${_CONFIGURATION}\" を実行\n"

	xcodebuild \
    -project "${PRODUCT_NAME}.xcodeproj" \
    -scheme "${_SCHEME}" \
    -sdk "${_SDK}" \
    -configuration "${_CONFIGURATION}" \
    TARGET_BUILD_DIR="${BUILD_DIR}/${_CONFIGURATION}-${_SDK}/${PRODUCT_NAME}" \
    BUILT_PRODUCTS_DIR="${BUILD_DIR}/${_CONFIGURATION}-${_SDK}/${PRODUCT_NAME}"

	_RET="$?"

	return "${_RET}"
}

#----- 後続のビルド処理で生成物を格納するディレクトリをクリア
if [ -e "${BUILD_DIR}" ]
then
rm -rf "${BUILD_DIR}"
sleep 1
fi

#-----iphoneos
_SDK='iphoneos'
_CONFIGURATION='Release'
Xcode_build
if [ "${_RET}" != 0 ]
then
	printf "<!> xcodebuildが${_RET}を返して終了。\n"
	exit "${_RET}"
fi

#-----iphonesimulator
_SDK='iphonesimulator'
_CONFIGURATION='Release'

Xcode_build

if [ "${_RET}" != 0 ]
then
printf "<!> xcodebuildが${_RET}を返して終了。\n"
exit "${_RET}"
fi

#===================================================================================================
#		Create .framework
#===================================================================================================
#-----frameworkフォルダ作成
_BUILD_DIR_NAME="_Build"
_BUILD_PATH="${PROJECT_DIR}/${_BUILD_DIR_NAME}"
_FRAMEWORK_PATH="${_BUILD_PATH}/${PRODUCT_NAME}.framework"
if [ -e "${_BUILD_PATH}" ]
then
	rm -rf "${_BUILD_PATH}"
	sleep 1
fi
mkdir -p "${_FRAMEWORK_PATH}"

#-----バイナリ作成
lipo -create \
	"${BUILD_DIR}/Release-iphoneos/${PRODUCT_NAME}/lib${_SCHEME}.a" \
	"${BUILD_DIR}/Release-iphonesimulator/${PRODUCT_NAME}/lib${_SCHEME}.a" \
	-o "${_FRAMEWORK_PATH}/${_SCHEME}"

_RET="$?"
if [ "${_RET}" != 0 ]
then
	printf "<!> lipoが${_RET}を返して終了。\n"
	exit "${_RET}"
fi

#-----ヘッダなどをコピー
Copy_path_to_path()
{
	if [ -e "${2}" ]
	then
		rm -rf "${2}"
		sleep 1
	fi
	if [ -e "${1}" ]
	then
		cp -Rfp "${1}"	"${2}"
	else
		printf "<!> コピー元がありません：${1}。\n"
	fi
}

Copy_path_to_path \
	"${BUILD_DIR}/Release-iphoneos/${PRODUCT_NAME}/Headers" \
	"${_FRAMEWORK_PATH}/Headers"
