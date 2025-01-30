List<Integer> myCurrentItems = new List<Integer>();

// Fill the list with default values (e.g., 0) for a size of 5.
for (Integer np = 10; np < 15; np++) {
    myCurrentItems.add(np); // Initialize with placeholder values.
}

System.debug(''); // Add a blank line to separate the output.

// Loop through the list and update values.
for (Integer i = 0; i < myCurrentItems.size(); i++) {
    System.debug('Item: ' + myCurrentItems.get(i));
        Integer NewItem = myCurrentItems[i] * 2;
            System.debug('NewItem: ' + NewItem);
}

System.debug('');

// Sort the list in ascending order and descending order and print the results.

myCurrentItems.sort();
System.debug('Sorted Items Ascending: ' + myCurrentItems);

List<Integer> DescItems = new List<Integer>();
for (Integer i = myCurrentItems.size() - 1; i >= 0; i--) {
    DescItems.add(myCurrentItems[i]);
}
System.debug('Sorted Items Descending: ' + DescItems);

System.debug('');

List<Integer> CarlGauss = new List<Integer>(myCurrentItems);
for (Integer i = 4; i <= CarlGauss.size(); i--) {
    CarlGauss[i] = CarlGauss[i] + CarlGauss.get(i);
    System.debug('CarlGauss Numbers: ' + CarlGauss[i]);
        if (i == 0) {
            break;
        }
}

System.debug('');

// Create a new list and add the values of the first list to it and multiply each value by 2.

List<Integer> MultipleNums = new List<Integer>();
for (Integer Item : myCurrentItems) {
    MultipleNums.add(Item * 2);
}

List<Integer> MultiNum2 = new List<Integer>();
for (Integer Item : myCurrentItems) {
    MultiNum2.add(Item * 2);
}

/*

Try to catch any errors that may occur during the below code.
The code below performs the same operations as above but with a try/catch block.
This is to ensure that if an error occurs, the code will not break and will instead print the error message.
I have used the getStackTraceString() method from the Exception class to print the error message.    

*/

try {

if(MultipleNums.equals(MultiNum2)) {
    System.debug('I have now made both list arrays equal to each other!!');
    System.debug('Here is list 1 - ' + MultipleNums);
    System.debug('Here is list 2 - ' + MultiNum2);
} else {
    System.debug('I have failed to make both list arrays equal to each other!!');
}
} Catch (Exception e) {
    System.debug('Big Error Man! - ' + e.getStackTraceString());
}

System.debug(' ');

List<Integer> MultiNum3 = myCurrentItems.Clone();
System.debug('Here is a cloned() method from another list - ' + MultiNum3);