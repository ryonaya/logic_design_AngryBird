#include <iostream>
#include <fstream>
using namespace std;

#define KEYCOLOR1 "F6F,"
#define keycolor1 "f6f,"
#define KEYCOLOR2 "F6F;"
#define keycolor2 "f6f;"

int main () {
    ifstream coefile;
    ofstream txtfile;
    string coename, filename;
    int lineChange;
    int mode;
    filename = "file";
    cout << "Input : A COE file name (without file extension)" << '\n';
    cin >> coename;
    cout << "Input : How many bit to \\n" << '\n';
    cin >> lineChange;
    cout << "Input : Mode (0 means verilog ver., 1 means debug ver.)" << '\n';
    cin >> mode;

    coefile.open(coename + ".coe");
    txtfile.open(filename + ".txt");
    if(coefile.is_open() && txtfile.is_open()){
        string cur;
        int cnt = 0;
        getline(coefile, cur);
        getline(coefile, cur);
        while(getline(coefile, cur)){
            if(mode == 0){
                if(cur == keycolor1 || cur == KEYCOLOR1 ||
                   cur == keycolor2 || cur == KEYCOLOR2)
                    txtfile << "1'b0, ";
                else
                    txtfile << "1'b1, ";
            }
            else {
                if(cur == keycolor1 || cur == KEYCOLOR1 ||
                   cur == keycolor2 || cur == KEYCOLOR2)
                    txtfile << "0";
                else
                    txtfile << "1";
            }
            cnt++;
            if(cnt == lineChange){
                cnt = 0;
                txtfile << '\n';
            }
        }
    }
    else{
        cout << "failed to open files" << '\n';
        exit(0);
    }

    coefile.close();
    txtfile.close();
    return 0;
}
