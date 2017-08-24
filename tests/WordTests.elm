module WordTests exposing (..)

import Array
import Byte
import Expect exposing (Expectation)
import Test exposing (..)
import Word
    exposing
        ( Size(Bit32, Bit64)
        , Word(D, W)
        , add
        , fromBytes
        , rotateRightBy
        , shiftRightZfBy
        )
import Word.Bytes as Bytes
import Word.Helpers exposing (max32)


suite : Test
suite =
    describe "Word"
        [ fromBytesTests
        , addTests
        , rotateRightByTests
        , shiftRightZfByTests
        , fromHexTests
        ]


fromBytesTests : Test
fromBytesTests =
    let
        bigList =
            List.repeat 400000 (Byte.fromInt 0x01)
    in
    describe "fromBytes"
        [ test "32bit empty" <|
            \_ ->
                Expect.equal
                    Array.empty
                    (fromBytes Bit32 [])
        , test "32bit from string" <|
            \_ ->
                Expect.equal
                    ([ W 0x666F6F20
                     , W 0x62617220
                     , W 0x63617200
                     ]
                        |> Array.fromList
                    )
                    ("foo bar car"
                        |> Bytes.fromUTF8
                        |> Word.fromBytes Bit32
                    )
        , test "64bit from string" <|
            \_ ->
                Expect.equal
                    ([ D 0x666F6F20 0x62617220
                     , D 0x63617200 0x00
                     ]
                        |> Array.fromList
                    )
                    ("foo bar car"
                        |> Bytes.fromUTF8
                        |> Word.fromBytes Bit64
                    )
        , test "32bit really long input" <|
            \_ ->
                Expect.equal
                    (Array.repeat 100000 (W 0x01010101))
                    (Word.fromBytes Bit32 bigList)
        , test "64bit really long input" <|
            \_ ->
                Expect.equal
                    (Array.repeat 50000 (D 0x01010101 0x01010101))
                    (Word.fromBytes Bit64 bigList)
        ]


addTests : Test
addTests =
    describe "add"
        [ test "32bit identity" <|
            \_ ->
                Expect.equal
                    (W 1234)
                    (add (W 1234) (W 0))
        , test "64bit identity" <|
            \_ ->
                Expect.equal
                    (D 1234 5678)
                    (add (D 1234 5678) (D 0 0))
        , test "32bit max value" <|
            \_ ->
                Expect.equal
                    (W max32)
                    (add (W 0x80000000) (W 0x7FFFFFFF))
        , test "64bit max value" <|
            \_ ->
                Expect.equal
                    (D max32 max32)
                    (add
                        (D max32 (max32 - 1))
                        (D 0 1)
                    )
        , test "64bit carry value" <|
            \_ ->
                Expect.equal
                    (D 1 (max32 - 1))
                    (add
                        (D 0 max32)
                        (D 0 max32)
                    )
        , test "32bit wrap" <|
            \_ ->
                Expect.equal
                    (W 1)
                    (add
                        (W max32)
                        (W 2)
                    )
        , test "64bit wrap" <|
            \_ ->
                Expect.equal
                    (D 0 1)
                    (add
                        (D max32 max32)
                        (D 0 2)
                    )
        , test "32bit add 2 largest values" <|
            \_ ->
                Expect.equal
                    (W (max32 - 1))
                    (add
                        (W max32)
                        (W max32)
                    )
        , test "64bit add 2 largest values" <|
            \_ ->
                Expect.equal
                    (D max32 (max32 - 1))
                    (add
                        (D max32 max32)
                        (D max32 max32)
                    )
        ]


rotateRightByTests : Test
rotateRightByTests =
    describe "rotateRightBy"
        [ test "32bit rotate by 31" <|
            \_ ->
                Expect.equal
                    (W 0xFFFFFFFE)
                    (rotateRightBy 31 (W 0x7FFFFFFF))
        , test "32bit rotate by 32" <|
            \_ ->
                Expect.equal
                    (W 0xDEADBEEF)
                    (rotateRightBy 32 (W 0xDEADBEEF))
        , test "64bit rotate by 28" <|
            \_ ->
                Expect.equal
                    (D 0xFFFFFFF0 0x0F)
                    (rotateRightBy 28 (D 0x00 0xFFFFFFFF))
        , test "64bit rotate by 31" <|
            \_ ->
                Expect.equal
                    (D 0xFFFFFFFE 0x01)
                    (rotateRightBy 31 (D 0x00 0xFFFFFFFF))
        , test "64bit rotate by 32" <|
            \_ ->
                Expect.equal
                    (D 0xBBEEAAFF 0xDDEEAADD)
                    (rotateRightBy 32 (D 0xDDEEAADD 0xBBEEAAFF))
        , test "64bit rotate by 36" <|
            \_ ->
                Expect.equal
                    (D 0xDBBEEAAF 0xFDDEEAAD)
                    (rotateRightBy 36 (D 0xDDEEAADD 0xBBEEAAFF))
        , test "64bit rotate by 64" <|
            \_ ->
                Expect.equal
                    (D 0xDDEEAADD 0xBBEEAAFF)
                    (rotateRightBy 64 (D 0xDDEEAADD 0xBBEEAAFF))
        , test "64bit rotate by 68" <|
            \_ ->
                Expect.equal
                    (D 0xFDDEEAAD 0xDBBEEAAF)
                    (rotateRightBy 68 (D 0xDDEEAADD 0xBBEEAAFF))
        ]


shiftRightZfByTests : Test
shiftRightZfByTests =
    describe "shiftRightZfBy"
        [ test "32bit shift max by 31" <|
            \_ ->
                Expect.equal
                    (W 1)
                    (shiftRightZfBy 31 (W max32))
        , test "32bit shift max by 32" <|
            \_ ->
                Expect.equal
                    (W 0)
                    (shiftRightZfBy 32 (W max32))
        , test "64bit by 28" <|
            \_ ->
                Expect.equal
                    (D 0 0x0F)
                    (shiftRightZfBy 28 (D 0 max32))
        , test "64bit by 31" <|
            \_ ->
                Expect.equal
                    (D 1 (max32 - 1))
                    (shiftRightZfBy 31 (D max32 0))
        , test "64bit by 32" <|
            \_ ->
                Expect.equal
                    (D 0 max32)
                    (shiftRightZfBy 32 (D max32 0))
        , test "64bit by 33" <|
            \_ ->
                Expect.equal
                    (D 0 0x7FFFFFFF)
                    (shiftRightZfBy 33 (D max32 0))
        , test "64bit shift max by 63" <|
            \_ ->
                Expect.equal
                    (D 0 1)
                    (shiftRightZfBy 63 (D max32 max32))
        , test "64bit shift max by 64" <|
            \_ ->
                Expect.equal
                    (D 0 0)
                    (shiftRightZfBy 64 (D max32 max32))
        ]


fromHexTests : Test
fromHexTests =
    describe "fromHex"
        [ test "tail call" <|
            \_ ->
                Expect.equal
                    6400
                    (List.length <| Bytes.fromHex "f61363eaa08cce68283076fa1ba17ffeeade05f89e216891c703e7e0b5e671e9eb94b763d12486bfa91e5465c4df1941f63e607e476f9d91eb28c17a75030c46472422d94d1b62eaeb0b734f330c1f7b5ccf65456f81c9eb44f1ef56adf4689ff109ccd37c3909f3d441fa3fcff33cb404da3dd47f1d95a5b9a59afcc7822efbd18bdcd9c64524e14e0712be005b16f5d6a60fb3dd0ca9c9318ee9f529750663cff47b7393095abd40a4e3532e0b5545ba7d046bf315ac5e96f205c83d9597ded38ad02a4b4b548e91619486c1cca2ad98a544832802476dcf1a15fd69aa8a74c597048556d4b95c2b864edf2166a5345867f683e39a21fdc44e421d177b862d8d613e0d1c6c3230f55b38e7b7a105e2e20b42f38ea4e3165dd6b4afaed134121331a74806da6711d7277b25e9456abf1ed9515c90e934c082f9923b96743c2a404e67c07ae8ff07b9343e2120197ed4f4194b465131bd041b000449362c457efa02a5fde15ca31a83c8aa64c5e6e6284d125837394325e910333462f8c1f7142a938985a4fffa531d2ce7753e744dc30f0d9eb9b0e9157849da470d43fafcf6b94a3ce22999adb970a81cdcf58b59ae245248531ee935b8ae3d68d380a0f92c8d6fe69cdaf263546283712250f3b2f072297c8eeb0c2cb128a4bd3b157b99bc904aae391ed1c52ddc070fceb9730191e3da62f07f1aa36b9d566ecd6b5381b0a822bd435c007a4bc77a1e6897d5ee9a5eac240342db41eff79ca411eaf05c0fbf413b42fe452bb70925c57952df2012cae9e74f9d17af441cbe8790fa1ad0e2bced4fbc6b6980778c502d88525a400111d7d65bf6959472f6043ed104988530876f213b0b34209536437e1dfe0df5701abe16afb61e99826bb5f25c6e332501080fda46466db418f145dfc0c0c2e865cde8d2d3467a667b651bcabaa2b3555e2714a26684dee309a49f78faff3fc1eb129c30500c71a265cb7cef7206e0bf4dccc8a0212d4d566f379a7252244d2707d12158ac72caf5488521880c04810bd9df71fd02a983b552917cf55195b4c2c3f2c07372df4f092d7a52be110360e1074858e08e6048a7bb9c8d287dbb3c3b265dc1a927bbc6831b9457b9086b43e7e1efc5724fbb63d4b03f173461fead3a38fb6c21556df80e1bba77a079a3f3c86ebcffdbcc209ee53c62604182c7ce6602b20804835fad5034d4fb9bec15382ab69850428df8bf8264edb1766a7c68688b6bdf793af8adf16ecb2bd4ea28d9b6c269fecf1bac8f5232c952fba08743e7dc0f37a901a0bf9ad1854f70fa44a013991952acfda2d6feaddc8bf9ac4e278cfb8459bc60bfadf366ebaf9aa5d153e9438e94febb445c2ddd0fa498173bdcfff2b48dd9dfbd3da334e593787237bbe2c9b20cf0def9e888cb4be4ff67b429e7c9851b2807033853435c4232e9dfa0a4326b02a7ed2844b77e7695572723d8ed86e14ad25ff765aa9c3605f1922fcad786a3bd4e703b3661fe79fdc7dcefafb833af63ff70028e51465d24ddf6900024ce41860bef99872e543d6478108077f1d7d7aed6c08d79ef49b7e71d9c6b0c33112da506f3aaffc887a914914a3ef73f7b407380d9feef2dae2e95da0c26b4ab574f626903d665d49fa4543b1391f94b26d4fa2543beb8b37ca9783bcf2bc134a88f0459a88583fda5186b9ef2e143bce07a8aeb84369c28bb0fd6696ce0fa780dd5d500691f1fe8a0eca2e16f969f3bb11a6dfd26cd6334744af88b6baf291c8d091b86ce0c02409808412d1218d370a29de981b1ead480ae4126ca55ff14cb31131f135fb4f4ab965490a964cfa702bae947a0abf7b9b471dca84eb137842b00db29cda580bcd1a0b8d67eec24e59a02e7cf819e5bd878c503c53e07c141e4024981df27d6245cc11c5dd3327d53df807fc84d117ef972b39ec6c2e004139f3f466e6f6d1ff2f1fe686bd1bf43bb7a3e9a7c2b8dc8e64d4295f304c268c204c0b839a600c4ef3a6184499f1adfe312441e314499a166af7bd09429385515ba8c892bab672be3dff1583f67cbb7935098f530bfbd7140416438f15cc733d66aab9f8aa72abe9688b6cc944e5b3595dc4405c1c581a03daa08b352c3f96acbbb26e49ec1d2e4cfdcb9c9927e51c0b05d50382b7e6e9625926c2afe865562bd56043eb122e604588301357f1f35bfab7bc274b8110bbbc0a39a863ece638473e24d9709f1ee88f72696faa458909c4fdfa4a3aea7e078d58399ad5ac3ac36b70809d6ef5773d7756d81fe4952e9be6431fdac566776332eda71899a8cb7e14f7041e3ab7cfc5999ffc92bb635c88db218d677f87a545591512b0145520cee04c1fda6858711762d8576673228b571003d36ecdc070347c78fcdfca53c34c39ea34307c5a03a96f7a6919c065339d2174825f349370970983d62640073b6cae5c01deeb2f10021c10b21b17bdfdb18c0e0ac748932f037cb03ef209f1e1a6aa1bd9243959fea7f515b2e8ed7f424abc1add157e21f3f062a887e18ca66e90a9945aaeeb6d581186f3fc11b62b99bf4e2599e849d267f447b751634c973aa1496fe6ed75db94b55e55fe0406657c859ed891be3017137588771c05ce36ce5ef6090e5e6d273d29c7a6296e529f63343a8e74f5d5825efac1625837861792303bfa418045c2c9e56f5f1e8f2f4bc651bdd1b42d8e86d30a7f03967708bc4eab87be20d17450c35ec1fb3e04f0fd4e54752cdfc3dfb6f80b1dc54742ca972c5765bf1ce08d33a21c4c05185e4c2643b31d0a48675d7536a32a31eb39403ae39a5287a63c04fdfea48a072df995595f03f1e48e767c44273920d412b91e19ed0adaa24d226012216df86bff7570f8e8bdb066227fa0c64253ae262e4098a6a11f6a9982521302c2ff03bdfd4043a78946c4e9a4f18f6e00790ea2ce7e6473b84e8ed7d649b2524bde5887b7e8a1c7a935abf9765a8c9dea1fded443b0e6039b2ec3d7c957b29334625333bfecffdbd110c21027491ce887ceab255e86b1d8b2268633dc2a98281541804c65bbd276896ec3c8281bd4d041fbd0205f7e3c55a5cc62567f20c78356e26c5c59d3be1a4a861d7c096138d7a12e0a5fc6f60a2cde96c4ca22e8e55781db73cdfcd307299d1d3bc63ba7bd813deb963e358c9fa0d50c4a0987d165f71e73332bdf286236e98aab114f6dd74f60ab20462bb0616411934e8eee78de0495702700714243c4c854f7f7b5121aa4d1e314f209ffe3e92cd26ee4f74d91e27f28cbb643bf2055a2128ee3fd330c23da3a00dc60c9bba28f30178612de36234423ade7c70d8c5c1f39ec50984f004f0206606fb0ac4d12a132d4fcc1993f397ce729ff8babec6a8841ace806d4ab88e1deb0268a261ccc0b6123b3940d21b791e9dc880228c4e385a02cf4d9526253e2297c9b5db5bf31463180350ab862002bb241fbbaf2aa698ffbf9117046d9429b8d22289be988e4ba2a771b861984b592c6d6d52698016f2fbbadc87c3054d776604d78c5101e590fb274b1a6af1e4a7f9e279ec5877e56bd45a7745d9d8984fb595ae679e7e4009f7005a1dcf773313abea0d3285f55d2d14062cf84ecdbdd92ced70c2adf8e6de1d9a666a97147fc6c9ecefccf7e3c4604228c1482bcb033f5374e54484552038f55d37a8caaf12e8db52e861b62a632be727ffdf77bcb4a6b293d4962d7f363f08b29480713032a06983c099cbb082b78a6bae623a871638d2b00660b05c701addff469a937e2816fce73f1e3d5f692cb35c967c7c14721d3a35444913d615f2fdad169d38833c731be62d95141e5fb1eb627ed3464b0f7d728854f960d46feeee25c9326826b5df4fe851a959d4ad6eb8e5300f9f14377f0313fe199f3dc4373ace2a002c4fdd811f557400136b9c8ca54d72d99057304b743c0c51d6fb5df4680f00b08be6fa8213955e424aca723337020dd920fc430a4d6d44480ff5824e015212e98ed45509b310d71806d9778af86cc9b657ebb8e4170d70a751137b6d8cfe29543cff363f882fa72a5080f5ba6ff36d183d0cd70058845615a53d8f78917b0d989d50e44c1958951f2fa732ea2400c3a9db47e7879b39bf3b115b07979930865eb9afa957eef46b9fac367743a0f9910e388532a0659672c0a0552bf42b875c4e9905cb88906cef54ce150ced6a48a0f25cacfe744002394e571343b4cfe7560f443893088626eae39d2d390f0a53b8fb50a6942bb3e5da8a407e97020db83e4ac23249ff588c23f7216446d20984a0d11b593cec47a81e1e627c6f046e63daa61cd935958f05643663a37a5dee42221dc5af3edf82b1cdb2c5f612e2794ef3cc59179ff0b2f873486ad31fd941f40487578fe12def69afed72d5c9c5b7e2506381d3ce3b49cf19d63eda7b6d8b040fb6d8e06efe13388b7870ffdcd5ae87bb149df50b9cddf11e88e8a2d64252d90b53508c2d7978872bfac75e9339e8a6fa87b3649e3bf5c64a056f117a7f21dbc005c87a66c7a5bc551c80d9351aeda5d663ce0acf4119b665f6db11ae4d7d72f6754692610f2241d286a2570c9f43ee1751f3cee6d6d12936023589b9d4f006744bd5bc657a787c6adf35c25ef174e785f82c982a21a68786d28460e43b01ff032e7ae0bc302ed7e4d04201743708fae7018050e44b1f381d0dd08077ab39c56bc63fe6ac58ccb80a00cffc969a858e0713f8df5c7bc5a4c35c21d0ba4b1ec074bc2bb67e1bda89a218e79b0c42750aabd79a2bdada1e3440678038f4443a59e5b846397aa0e1b175bf8fc61d565fd89cf4701da690b44e5bd5f4a06fbd15f688619955e71069984b9ed16512fecc5fa213829d07c40f5cdd4f86f071df350123602bf30f92f8a6ec5cb4603364430784dcd694479fb5c48f7c3d1043d124e07f5c05fc384f18431fa2409fc8ad4c380cf676e8ac4830f0360521e92dbc6afd64fe2d56ab6e50d7ad187e0a19046f5a000a6a837fe708469d913a6176c88dbe9aeeadebb01828ca5f65758a6e8f35d529bfb84b07a6c3308bc99161681c178de8d38da18e752984fb322e050e7625124fbe6a2a8eabeb14c7542dd249e190d11756d3628facda6e4926af6442e2c8773aaf88075a1e075c1adc169a623e7ef1ef1e8915f9e6c4ee13ea029052fba46db13818c9b428a06f4c0655a3fb5c6b5738d4b6a2154a6d6d1f252f7086e8435d7e04245ae4f13db5257cf1d35c63de6aba1f63f02b015f5436803ceb25d22dad67b9b3a132a066966de6f214cc7a60923da897e98332220920a333eb79e0e8c73500ce86e65da47aebeb614d95c9783788165a7464063cf6a5351b57c83bfe11b0807cf147527dc968344566fd79aec16412b47918a537818ddffd165b0af7f59fe2c5ca9ea47bebac69a6464db28a999944aee1e5369b149f48e0127a7659d9cbcdb1f9337e26497f318cd7cc9b9525ef534f9214e1ee16a418cc326da7ae27fdea49674e060549a9340000c45d56ce2ee8a075ecd0baef65f9ca5e7bc47d46fbe194fa3764a054f11b09a97b1f55fc1daaa772b7288606a791e07eedf54f9e8d599a9b35c17fd3208eb0ba3a0a1b1885426e72bb14dbc53588197b0b64ab977dfa643392452b2cfe34fc1c49462f882e57fd5b42ba4093d6877a3b1d361999926df9a894172bc953b6f5b5f0fa19b6e0925a1792423dd851360da76b96210c935a62e484600710e7bba36e774f6208639b8f8cf3d55afd6f3cd9a73daa4c584968a5cdaa47486b82ec0f30256c91e87e19a4a4af9b2068f842e624da9a21e57c40cc4d4df57541ebf140e144792ebdfbb49f450dbb1682b4ef3d048b8f291cf38ade4bb69116f9eb713e6a1aa0c2efa0158a59545dc5b36aece53198b1ea6378ede4ae2e44b3fd4a1512b4f007d4e636e46cc7cdabb364e4e0e6914927ee23d111e560fb36d5b4d084c3a60dd6ec0984c84e77c0ca6afbe874490ee51abdc5c79fe948658e038644665927bb3692c2546a375174e572e23f50158fb6b1ddaf223ff94eb675c6db7065dd21404f4f796c722f3d3322517fb11b52fb0215d84baa981b5a3412a51b1a27567be548aa9495873f2343a9913c057d083c126d360027535954298e28ae0b54cc1df2492c7c97516debeda3b980052040392ee27d356017bb24db10d7fd0b9547efaf7c5b993a7ac37d793852b277a902da9e9c37541e8d48b393c13b6ee292d0d86307c25346a749c12f8fe33c24c35407a9c2ebc4295d08e798c8db6a57f26ec35812e613828206a057d1f485d41440a8987c22ed492e03a9344e3f5a335d2a95d4c6513fb7b3020038250ef54e44cda5b3f4633746a842e2ad7bf0a43e7d0b37204a8a41ade245cb1bb4b8f45cfc03e6424f360ae774cc784c7675b240f7199184c7197f2cb6d8e748a67aeac4e4eb548db823cef53aa955596856ea01765c8b47658763fcd7c23e0722dc3f4fa38cd5dc55b3eb39a1e25f1c781cb648a0dd0eb34b5a53e4ee0bb6a050675bc5e2ef52764e6dc978527e80dccf4e7ddf1da3000ea21db9aea3bc395a59a2a7ee481ab4a4ccdad07df5859fe39474a68c96b64ba19155fc209ddbae7f651589927e17e1aef780690f3100a377f0179b18b31fd5b4418c84038573fc559b496a782beec3dcf6e9faf5aef676e10bbec34b1be5888fda49b91e02890d2524c5b369f8a54175f29dedf8156fff690cf186ec77104a798315033bbd27c8362811ca2d8c4642c31222a8e00e7326561c384cc56ea905bc6477ca205d5415d2ceb6198c91d8b00c7f029575400bd3f2621c7d9ca9b6a09ea6f776968b19dc3f3e3b064eac64729960c51a7e543eee830724813acf420368711d6f65ef7d05c6a128fb3a87f170b2def1a1c5f1155f5232d9c16789521661ec721d55308879af1f065f19ca87929f21109110c0960ea70cc1a3ea7ff0c1d3407de92ef7421e42df5c9ab31d2ec0a750a9522869cbe4cabd66908d5823ec0494c639b7ebb4ddc70ab214d026efe21393454cd593bcc7026c50f116bdf47f3d11d676b9b5e59f85c791343890d1e02b146be7dee670a09841052c4e556962c6df3409fdfcdd4ac53f7f64b201dda237f8a38b0d0cef58d4650fabfdc98d7de72568584869a5c7cf99060c08211a107f6a76a028aa41d5fe00f6d4ebc065b8e80cfbcd65a444ffebfeae92009a90134b906a8ef86b6f015e394011dfe3fbfc10bb74cf1a54c2d96196fe5f63114791e29209bd45f47fc33c3977c9a3da562fa95a5bc53121283c78887edbf83148738d99db95d7f07c02df282263fd4c7e3bf913391970b57d1279fdb66e899f9aa294cd677f75056ba8902dca49b6e17c06490c9532a0b5c942ac1c2f81dc0645053f5535e1e9db569c9770f6e29642577ae06df77889cc14b4590e707abb0c5283d559cd24f91b44c63c1a2e966417177e085fe753f2a06750c8fa01c3ec59c806a003b8b16e6d3e0ec753fbcdea07c5f9070aee2ba4d9c9fe41096bc23796af75e6797def0f784b5c7f42e3efeebb67d526959368682043a60b6335e1666b0fb7f0e3a445a6e57398ad10706439db08f9ad285f72041ddc306f2fe7873f7ff1b6066ab51df95bbeaa99e42a95930ead4de4edd9b240779c84b5960a1b8c7b5c59703639ded283357a8be798e8c3fc60b91209898ee6d68b8a25bf250713065988756eb8eff705dff1cb4142c6934e282581a7f76fbce4b22b06d2c0b29dc9ef2b5e3ab8ba3088c5f5a019b098c9ac0e7977edacbe8c46184da2f96384f16c262b73c3c3a647b4ed6f54976bc42ebd189d3d032fe11ca7c5d93f5a97e5d996066efc31601b023361482de5fab48a2a50791b12084234adc2b8261de33d1bef98dd41ac18812baa29667428e5cea59abef65842c0479e0016d09f6bd0f48020e3608a5b714188c44bb3708bb57c46b669fa3ebade5a2149c90bf16ce572d0d1efe01e66f5c1e227d1166b33f1253726596e13a3eae28430e4506647aa20d3a9c54346f62c6a007bc276ab4b21303e91963b20246c47905c6e864425a76450516c734a339da4ac6927bd79f9cd0724a02947ad66edf00d766f97d42d65a71171ec567244d0d8ac9807d21d657e11b0fa197c0291f547c325f06a5e886b52dcb04ed605514d6cc9b26a9ddfb9bbb6ac476ec166cc0ab37912f7e72a5d41cb7ab699da4d849dcacb5c5906071a0d5ede3130fd233fb69cf9e58ff67fd5707cb32cd549900347587a40daf5dcb2fb71105e681a7f13806a0945bd7fa7187fcb4eba0b0d17f6d3809e06f852a7a90d5708761effc370f08672da8b6ae84df6221507420d2a86c9a9fe56b805b027cb798f225894367d8f56fb4d009f8b9c5ee8cebc823111dab23a63d624f63f53be3d6c0a20c12263e4436e462407d72e3d854280d361131c169d9531430e9c556d0c69d57d6ecd4978b6926c0088162b1e6139fc3e8579717b395c0d1d330f56604f4c2b78838058d1152e689b0b8ebb86e47bd8ca858c036b768013bb4edf7e206cdeb617e883b879c90be1fe798904ff76cfbb804991fa6dbcc8ea244855f434cde71b64861e90f83bf1802fb84d31107ffe4d66bad37e0a73fd3a6007b9e124d82f0567439908d4d2a7ed38b222684267d13787be99b5c803e7ad7875536c79f77d1a27083b4a97f5f7cf204d52d11b960d21e83e2aca32d54ee973796abeba919a02acbe4e7bc80ea7cff073249625747db29323cfe3cd4ffa9659fa47fe6f0d4f66fe4b18c6f0848094af0bdfdce86ae8938f53d02923dab35d33e2335521d562ee2699e25196bf4ac765fdccceebde156ce4b875c3bbdf40e6081874eb57509b412b8ef3444227cd0f1b313391b639cde49b3906d91dc46ad8e08452e799e6c408151495c87d24d015d88e5c50d1e4d8a3babdca95d2f3f9dbc30e17716fffa3eaec120e05cd1e1d80a4fe8e31c545fe524c2e0a1d61d2b599ba9e09b362030290b96fa722bd7d7af98769125c18c6079956730e9952cb65b7cc1c72d2f95aa7a18415a847d2a9b0288ab531fa55ceba1fe2741e322e44d3e002")
        ]
