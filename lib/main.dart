import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/painting.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart';
import 'package:web3dart/web3dart.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Flutter Demo',
      theme: ThemeData(
        fontFamily: 'GoogleSans',
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key, required this.title}) : super(key: key);


  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {

  final GlobalKey<ScaffoldState> _scaffoldKey = new GlobalKey<ScaffoldState>();

  var value = 50.0;
  var _value = 50;
  var httpClient;
  var ethClient;
  List recent_transactions = [];
  final myAddress = '0x60c81fb25aaa21f5B8Fb55B48667369E8A9187E7';
  var walletBalance;

  @override
  void initState() {
    super.initState();
    httpClient = Client();
    ethClient = Web3Client('add your test net endpoints here ie. rinkeby', httpClient);
    _getBalance();
  }


  _showSnackBar(String message){
      ScaffoldMessenger.maybeOf(context)?.showSnackBar(
      SnackBar(
        content: Text(message),
    ));
  }


  // Function to get balance out from the wallet.
  Future<void> _getBalance() async{
    try{
      List result = await query('getBalance', []);
    print(result);
    setState(() {
      walletBalance = result[0].toString() + '.0';
    });
    }catch(e){
      _showSnackBar(e.toString());
    }   
  }

  // Function to deposit amount to our wallet
  Future _addBalance() async{
    try{
      var res = await deposit('depositBalance', [BigInt.from(_value)]).whenComplete(() => _getBalance());
      ScaffoldMessenger.maybeOf(context)?.showSnackBar(
        SnackBar(
          content: Text("Amt. $_value added to the wallet."),
      ));
      setState(() {
        recent_transactions.add(res);
      });
     return res;
    }catch(e){
      _showSnackBar(e.toString());
    }
  }


// Function to withdraw balance from the wallet
  Future _withdrawBalance() async{
    try{
      var res = await deposit('withdrawBalance', [BigInt.from(_value)]).whenComplete(() => _getBalance());
      ScaffoldMessenger.maybeOf(context)?.showSnackBar(
        SnackBar(
          content: Text("Amt. $_value withdrawn from the wallet."),
      ));
      setState(() {
        recent_transactions.add(res);
      });
     return res;
    }catch(e){
      _showSnackBar(e.toString());
    }
  }


//  A funtion to call the functions of the smart contract ie. to deposit and withdraw
  Future deposit(String functionName, List<dynamic> args) async{
    try{
      EthPrivateKey ekey = EthPrivateKey.fromHex('Your Private key goes here');
      DeployedContract contract = await loadContract();
      final ethFunction = contract.function(functionName);
      final result = await ethClient.sendTransaction(
       ekey,
       Transaction.callContract(
         contract: contract, 
         function: ethFunction, 
         parameters: args,
        ),
        chainId: null,
        fetchChainIdFromNetworkId: true
     );
     return result;
    }catch(e){
      _showSnackBar(e.toString());
    }
  }


  // A function through which we make queries
  // through this function we will invoke those smart contract's function
  Future query(String functionName, List<dynamic> args) async{
    try{
         final contract = await loadContract();
        final ethFunction = contract.function(functionName);
        var result = await ethClient.call(contract: contract, function: ethFunction, params: args);
        return result;
    }catch(e){
      _showSnackBar(e.toString());
    }
  }


  // through this function we will load the contract from the abi.json file stored in our asset folder
  Future loadContract() async{
     try{
      String abi = await rootBundle.loadString("assets/abi.json");
     final contractAddress = '0x30670246B6f699907e187618A6466A3736F1586F';
     final contract = DeployedContract(ContractAbi.fromJson(abi, "FlutCoin"),
     EthereumAddress.fromHex(contractAddress)
     );
     return contract;

    }catch(e){
      _showSnackBar(e.toString());
    }
  }


  @override
  Widget build(BuildContext context) {

    var width = MediaQuery.of(context).size.width;

    return Scaffold(
      body: Stack(
        children: [
          Column(
            children: [
              Expanded(
                flex: 2,
               child: Container(
                 decoration: const BoxDecoration(
                  //  color: Color(0xFF3E376B),
                   gradient: LinearGradient(
                     colors: [
                      const Color(0xFF3E376B),
                      const Color(0xF23E376B),
                     ]
                   )
                 ),
               ),
              ),
              Expanded(
                child: Container(
                  color: Colors.white,
                  child: Padding(
                    padding: const EdgeInsets.only(top: 60.0),
                    child: ListView.builder(
                       physics: BouncingScrollPhysics(),
                       itemCount: recent_transactions.length,
                       itemBuilder: (context,index){
                         return Padding(
                           padding: const EdgeInsets.all(5.0),
                           child: ListTile(
                             leading: CircleAvatar(
                               child: Text((index + 1).toString(),
                               style: TextStyle(fontSize: 18,fontWeight: FontWeight.bold),
                               ),
                             ),
                             title:  Text('Transaction Successful',
                               style: TextStyle(
                                 fontSize: 18,
                                 color: Colors.green,
                                 fontWeight: FontWeight.bold
                                 ),
                               ),
                               isThreeLine: false,
                               dense: true,
                             subtitle: Text(
                             recent_transactions[index],
                             maxLines: 1,
                             style: TextStyle(color: Colors.black,fontSize: 18),
                             ),
                             trailing: IconButton(
                               icon: Icon(Icons.copy,color: Colors.black,size: 26,), 
                               onPressed: () { 
                                 Clipboard.setData(ClipboardData(text: recent_transactions[index]));
                                 ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text("Hash ID of transaction copied to Clipboard"),
                                  )
                                 );
                                },),
                        ),
                         );
                      }
                    ),
                  ),
                )
              )
            ],
          ),
    
          Padding(
            padding: EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 25.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Good Morning',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.bold
                      ),
                      ),
    
                      IconButton(
                        onPressed: (){
                          _getBalance();
                        },
                        icon: Icon(Icons.refresh, size: 24, color: Colors.white,)
                      )
                    ],
                  ),
                ),
    
                Text('Dhananjay Sahu',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                ),
                ),
    
                SizedBox(
                  height: 40
                ),
    
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                      Padding(
                        padding: const EdgeInsets.only(bottom: 25),
                        child: IconButton(
                            icon: FaIcon(FontAwesomeIcons.ethereum, size: 50, color: Colors.white,),
                            onPressed: () {
                      
                             }
                          ),
                      ),
                      Text( walletBalance != null ? "${walletBalance}" : "0",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 60,
                        fontWeight: FontWeight.bold
                      ),
                    ),
                  ],
                ),
    
                 SizedBox(
                  height: 10
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('Your main balance',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                      ),
                    ),
                  ],
                ),
    
                 SizedBox(
                  height: 60
                ),
    
    
    
    
                Card(
                  child: SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      activeTrackColor: Color(0xFF3E376B),
                      inactiveTrackColor: Color(0xA63E376B),
                      trackShape: RoundedRectSliderTrackShape(),
                      trackHeight: 4.0,
                      thumbShape: RoundSliderThumbShape(enabledThumbRadius: 12.0),
                      thumbColor: Color(0xFF3E376B),
                      overlayColor: Color(0xA63E376B),
                      overlayShape: RoundSliderOverlayShape(overlayRadius: 28.0),
                      tickMarkShape: RoundSliderTickMarkShape(),
                      activeTickMarkColor: Color(0xFF3E376B),
                      inactiveTickMarkColor: Colors.red[100],
                      valueIndicatorShape: PaddleSliderValueIndicatorShape(),
                      valueIndicatorColor: Color(0xFF3E376B),
                      valueIndicatorTextStyle: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold
                      ),
                    ),
                    child: Slider(
                      value: value,
                      min: 0,
                      max: 100,
                      divisions: 100,
                      label: '$_value',
                      onChanged: (v) {
                        setState(
                          () {
                            value = v;
                            _value = v.toInt();
                            print(_value);
                          },
                        );
                      },
                    ),
                  ),
                ),
    
    
    
    
                 SizedBox(
                  height: 30
                 ),
    
    
    
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Card(
                        elevation: 20,
                        color: Colors.white,
                        child: Container(
                          height: 65,
    
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              InkWell(
                                onTap: () async{
                                  var res = _addBalance();
                                   _getBalance();
                
                                },
                                child: Text('Deposit',
                                  style: TextStyle(
                                    color: Colors.black,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 19,
                                  ),
                                ),
                              ),
    
                               Container(
                                 color: Colors.black,
                                 height: 60,
                                 width: 4,
                                ),
    
                              InkWell(
                                 onTap: () async{
                                  var res = _withdrawBalance();
                                   _getBalance();
                                },
                                child: Text('WithDraw',
                                  style: TextStyle(
                                    color: Colors.black,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 19,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
    
              
               
              ],
            ),
          ),

          Positioned(
            top: 510,
            left: 18,
            child: Text('Recent Transactions',
              style: TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
                fontSize: 22,
              ),
            ),)
    
        ],
      ),
    );
  }
}
